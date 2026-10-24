{******************************************************************************}
{                                                                              }
{  Módulo:       inLibStockConsultaInfo                                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Datos y formato del resumen de propiedades, tarifas y proveedores que    }
{    acompaña a la cabecera de la consulta de stock.                           }
{******************************************************************************}
unit inLibStockConsultaInfo;

interface

type
  TPropiedadInfoStock = record
    Codigo: string;
    Nombre: string;
    TipoValor: string;
    ValorLibre: string;
    ValorLista: string;
  end;
  TTarifaInfoStock = record
    Codigo: string;
    Nombre: string;
    PrecioFinal: Double;
  end;
  TProveedorInfoStock = record
    Codigo: string;
    RazonSocial: string;
    Referencia: string;
    PrecioUltimaCompra: Double;
    EsPrincipal: Boolean;
  end;
  TInfoCabeceraStock = record
    Propiedades: TArray<TPropiedadInfoStock>;
    Tarifas: TArray<TTarifaInfoStock>;
    Proveedores: TArray<TProveedorInfoStock>;
    PreciosUnidad: TArray<string>;
  end;

function FormatearInfoCabeceraStock(
  const AInfo: TInfoCabeceraStock;
  const ATarifaDefecto: string;
  AVerCoste: Boolean): string;

implementation

uses
  System.Classes, System.SysUtils, inLibMsgArticulos, inLibMsgComun;

function ValorPropiedad(
  const APropiedad: TPropiedadInfoStock): string;
begin
  if SameText(APropiedad.TipoValor, 'LISTA') then
    Result := Trim(APropiedad.ValorLista)
  else if SameText(APropiedad.TipoValor, 'BOOLEANO') then
  begin
    if SameText(Trim(APropiedad.ValorLibre), 'S') then
      Result := SStockInfoSi
    else
      Result := SStockInfoNo;
  end
  else
    Result := Trim(APropiedad.ValorLibre);
end;

function FormatearInfoCabeceraStock(
  const AInfo: TInfoCabeceraStock;
  const ATarifaDefecto: string;
  AVerCoste: Boolean): string;
var
  Lineas: TStringList;
  Proveedor: TProveedorInfoStock;
  Propiedad: TPropiedadInfoStock;
  Tarifa: TTarifaInfoStock;
  sLinea: string;
  sNombre: string;
  sPropiedades: string;
  sValor: string;
  sPrecioUnidad: string;
begin
  Lineas := TStringList.Create;
  try
    sPropiedades := '';
    for Propiedad in AInfo.Propiedades do
    begin
      sValor := ValorPropiedad(Propiedad);
      if sValor <> '' then
      begin
        if sPropiedades <> '' then
          sPropiedades := sPropiedades + '   ·   ';
        sNombre := Propiedad.Nombre;
        if SameText(Propiedad.Codigo, 'TEMPORADA') then
          sNombre := SCaptionTemporada;
        sPropiedades := sPropiedades + sNombre + ': ' + sValor;
      end;
    end;
    if sPropiedades <> '' then
      Lineas.Add(sPropiedades);
    if Length(AInfo.Tarifas) > 0 then
      Lineas.Add('');
    for Tarifa in AInfo.Tarifas do
    begin
      sNombre := Trim(Tarifa.Nombre);
      if sNombre = '' then
        sNombre := Tarifa.Codigo;
      sLinea := '';
      if SameText(Tarifa.Codigo, ATarifaDefecto) then
        sLinea := SStockInfoTarifaDefecto;
      sLinea := sLinea + sNombre + ': ' +
        FormatFloat('#,##0.00', Tarifa.PrecioFinal) + ' '#8364;
      Lineas.Add(sLinea);
    end;
    for sPrecioUnidad in AInfo.PreciosUnidad do
      Lineas.Add(sPrecioUnidad);
    if Length(AInfo.Proveedores) > 0 then
      Lineas.Add('');
    for Proveedor in AInfo.Proveedores do
    begin
      if Proveedor.EsPrincipal then
        sLinea := SStockInfoProveedorPrincipal
      else
        sLinea := SStockInfoProveedor;
      sNombre := Trim(Proveedor.RazonSocial);
      if sNombre = '' then
        sNombre := Proveedor.Codigo;
      sLinea := sLinea + sNombre;
      if Trim(Proveedor.Referencia) <> '' then
        sLinea := sLinea + SStockInfoReferencia + Proveedor.Referencia + ')';
      if AVerCoste then
      begin
        sLinea := sLinea + ': ' +
          FormatFloat('#,##0.00', Proveedor.PrecioUltimaCompra) +
          ' '#8364;
      end;
      Lineas.Add(sLinea);
    end;
    Result := Lineas.Text;
  finally
    FreeAndNil(Lineas);
  end;
end;

end.
