{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArticulosResolverIntf                                    }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contrato de resolución consolidada de artículos, precios y costes.        }
{******************************************************************************}
unit inLibArticulosResolverIntf;

interface

type
  TArticuloOrigenPrecio = (
    aopSinPrecio,
    aopHeredadoPadre,
    aopEspecificoSku);

  TArticuloPrecio = record
    CodigoTarifa: string;
    NombreTarifa: string;
    Origen: TArticuloOrigenPrecio;
    PrecioSalida: Double;
    PrecioFinal: Double;
    PrecioDto: Double;
    PorcentajeDto: Double;
    PorcentajeMargen: Double;
    ValorMultiploAjuste: Double;
    ValorMenosAjuste: Double;
    EsImpIncl: Boolean;
    EsTarifaDefault: Boolean;
    FechaDesde: TDateTime;
    FechaHasta: TDateTime;
    Vigente: Boolean;
    TieneRegistro: Boolean;
    DescuentoAplicable: Boolean;
    procedure Clear;
  end;

  TArticuloCoste = record
    CodigoProveedor: string;
    RazonSocialProveedor: string;
    RefProveedor: string;
    PrecioUltCompra: Double;
    FechaValidezCompra: TDateTime;
    EsProveedorPrincipal: Boolean;
    Encontrado: Boolean;
    procedure Clear;
  end;

  TArticuloPMP = record
    PrecioMedio: Double;
    CantidadTotal: Double;
    ValorTotal: Double;
    NumAlmacenes: Integer;
    AlmacenConsultado: string;
    Encontrado: Boolean;
    procedure Clear;
  end;

  TArticuloSkuItem = record
    CodigoSku: string;
    DescripcionSku: string;
    EsActivo: Boolean;
  end;

  TArticuloDatos = record
    Encontrado: Boolean;
    RequiereSku: Boolean;
    Mensaje: string;
    CodigoArticulo: string;
    CodigoSku: string;
    DescripcionArticulo: string;
    DescripcionSku: string;
    TipoArticulo: string;
    TipoCantidad: string;
    EsActivoArticulo: Boolean;
    EsActivoSku: Boolean;
    EsVariacion: Boolean;
    TieneSku: Boolean;
    EsTrazable: Boolean;
    NumAtributosReq: Integer;
    CodigoFamilia: string;
    DescripcionFamilia: string;
    TipoIVA: string;
    TipoVariacion: string;
    PrecioPedido: TArticuloPrecio;
    PrecioTarifaDefault: TArticuloPrecio;
    UltimoCoste: TArticuloCoste;
    PMP: TArticuloPMP;
    procedure Clear;
  end;

  IArticulosResolver = interface
    ['{F86570C3-1584-480D-B04D-85E5D2CB3A19}']
    function ResolverDatos(
      const ACodigoArt, ACodigoSku: string;
      const ACodigoTarifa: string = '';
      const AFecha: TDateTime = 0;
      const ACodigoAlmacen: string = '';
      const ACodigoProveedor: string = ''): TArticuloDatos;
    function ResolverPrecio(
      const ACodigoArt, ACodigoSku, ACodigoTarifa: string;
      const AFecha: TDateTime): TArticuloPrecio;
    function ResolverUltimoCoste(
      const ACodigoArt: string;
      const ACodigoProveedor: string = '';
      const ACodigoSku: string = ''): TArticuloCoste;
    function ResolverPMP(
      const ACodigoSku: string;
      const ACodigoAlmacen: string = ''): TArticuloPMP;
    function ListarSkus(
      const ACodigoArt: string;
      AIncluirInactivos: Boolean = False):
      TArray<TArticuloSkuItem>;
    function DescuentoTarifaVigente(
      const ACodigoTarifa: string;
      const AFecha: TDateTime): Boolean;
    function DescuentoTarifaAplicable(
      const ACodigoTarifa, ACodigoArt, ACodigoSku: string;
      const AFecha: TDateTime): Boolean;
  end;

function DescuentoEnVentana(
  const AFecha, ADesde, AHasta: TDateTime): Boolean;

implementation

uses
  System.SysUtils;

procedure TArticuloPrecio.Clear;
begin
  CodigoTarifa := '';
  NombreTarifa := '';
  Origen := aopSinPrecio;
  PrecioSalida := 0;
  PrecioFinal := 0;
  PrecioDto := 0;
  PorcentajeDto := 0;
  PorcentajeMargen := 0;
  ValorMultiploAjuste := 0;
  ValorMenosAjuste := 0;
  EsImpIncl := False;
  EsTarifaDefault := False;
  FechaDesde := 0;
  FechaHasta := 0;
  Vigente := False;
  TieneRegistro := False;
  DescuentoAplicable := True;
end;

procedure TArticuloCoste.Clear;
begin
  CodigoProveedor := '';
  RazonSocialProveedor := '';
  RefProveedor := '';
  PrecioUltCompra := 0;
  FechaValidezCompra := 0;
  EsProveedorPrincipal := False;
  Encontrado := False;
end;

procedure TArticuloPMP.Clear;
begin
  PrecioMedio := 0;
  CantidadTotal := 0;
  ValorTotal := 0;
  NumAlmacenes := 0;
  AlmacenConsultado := '';
  Encontrado := False;
end;

procedure TArticuloDatos.Clear;
begin
  Encontrado := False;
  RequiereSku := False;
  Mensaje := '';
  CodigoArticulo := '';
  CodigoSku := '';
  DescripcionArticulo := '';
  DescripcionSku := '';
  TipoArticulo := '';
  TipoCantidad := '';
  EsActivoArticulo := False;
  EsActivoSku := False;
  EsVariacion := False;
  TieneSku := False;
  EsTrazable := False;
  NumAtributosReq := 0;
  CodigoFamilia := '';
  DescripcionFamilia := '';
  TipoIVA := '';
  TipoVariacion := '';
  PrecioPedido.Clear;
  PrecioTarifaDefault.Clear;
  UltimoCoste.Clear;
  PMP.Clear;
end;

function DescuentoEnVentana(
  const AFecha, ADesde, AHasta: TDateTime): Boolean;
var
  dDia: TDateTime;
begin
  if (ADesde = 0) and
     (AHasta = 0) then
    Result := True
  else
  begin
    if AFecha = 0 then
      dDia := Trunc(Now)
    else
      dDia := Trunc(AFecha);
    Result := True;
    if (ADesde > 0) and
       (dDia < Trunc(ADesde)) then
      Result := False;
    if (AHasta > 0) and
       (dDia > Trunc(AHasta)) then
      Result := False;
  end;
end;

end.
