{******************************************************************************}
{                                                                              }
{  Módulo:       inLibTraspasoRecuentoApp                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       08/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Traspasos entre almacenes hechos con la app de recuento (FZ-ISSUE-351):   }
{    cuáles recoge la caja y cómo sus lecturas pasan a líneas de traspaso.     }
{    Sin acceso a datos: el artículo de cada SKU lo da quien llama.            }
{******************************************************************************}
unit inLibTraspasoRecuentoApp;

interface

uses
  System.Classes,
  System.SysUtils,
  inLibCajaVentanasIntf,
  inLibInventarioNube;

const
  ORIGEN_RECUENTO_APP = 'APP';
  TIPO_RECUENTO_APP_TRASPASO = 'TRASPASO';
  // Serie de la referencia de la operación de caja (número = id remoto):
  // impide grabar dos veces el mismo traspaso de la app.
  SERIE_REFERENCIA_RECUENTO_APP = 'RA';

type
  TDatosSkuTraspaso = record
    CodigoArticulo: string;
    Descripcion: string;
  end;

  // Artículo y descripción de un SKU activo; False si no existe.
  TBuscarDatosSkuTraspaso = reference to function(
    const ASku: string;
    out ADatos: TDatosSkuTraspaso): Boolean;

// Traspasos de la app con origen en el almacén de la caja (y de su
// empresa, o sin empresa), en el orden del servidor (más antiguo antes).
function FiltrarTraspasosAppAlmacen(
  const APendientes: TArray<TRecuentoAppPendiente>;
  const AEmpresa, AAlmacen: string): TArray<TRecuentoAppPendiente>;

// Lecturas «SKU=CANTIDAD[;LOTE[;CADUCIDAD]]» a líneas de traspaso: una por
// SKU y lote. Las cantidades no positivas y los SKU desconocidos no entran
// y se anotan en ADescartadas como «SKU (valor)».
function LineasCargaDeRecuentoApp(
  ALecturas: TStrings;
  const ABuscarSku: TBuscarDatosSkuTraspaso;
  ADescartadas: TStrings): TLineasCargaTraspaso;

implementation

uses
  inLibInventarioRecuentoLote;

const
  MAXIMO_ATRIBUTOS_TRASPASO = 5;
  TOLERANCIA_CANTIDAD = 0.000001;

function FiltrarTraspasosAppAlmacen(
  const APendientes: TArray<TRecuentoAppPendiente>;
  const AEmpresa, AAlmacen: string): TArray<TRecuentoAppPendiente>;
var
  Pendiente: TRecuentoAppPendiente;
begin
  Result := nil;
  for Pendiente in APendientes do
    if SameText(Pendiente.Origen, ORIGEN_RECUENTO_APP) and
       SameText(Pendiente.Tipo, TIPO_RECUENTO_APP_TRASPASO) and
       (Trim(AAlmacen) <> '') and
       SameText(Trim(Pendiente.CodigoAlm), Trim(AAlmacen)) and
       ((Trim(Pendiente.CodigoEmp) = '') or
        SameText(Trim(Pendiente.CodigoEmp), Trim(AEmpresa))) then
      Result := Result + [Pendiente];
end;

function IndiceLinea(
  const ALineas: TLineasCargaTraspaso;
  ACuenta: Integer;
  const ASku, ALote: string): Integer;
var
  i: Integer;
begin
  Result := -1;
  i := 0;
  while (Result < 0) and (i < ACuenta) do
  begin
    if SameText(ALineas[i].CodigoSku, ASku) and
       MismoLoteRecuento(ALineas[i].Lote, ALote) then
      Result := i;
    Inc(i);
  end;
end;

function NuevaLinea(
  const ASku: string;
  const ADatos: TDatosSkuTraspaso;
  const AValor: TValorRecuentoLote): TLineaCargaTraspaso;
var
  PartesSku: TArray<string>;
  iAtributo: Integer;
begin
  Result := Default(TLineaCargaTraspaso);
  Result.CodigoArticulo := ADatos.CodigoArticulo;
  Result.CodigoSku := ASku;
  Result.Descripcion := ADatos.Descripcion;
  Result.Cantidad := AValor.Cantidad;
  Result.Lote := Trim(AValor.Lote);
  Result.FechaCaducidad := AValor.FechaCaducidad;
  // Valores de atributo desde el propio SKU, como las propuestas.
  PartesSku := ASku.Split(['/']);
  Result.NumeroAtributos := Length(PartesSku) - 1;
  if Result.NumeroAtributos > MAXIMO_ATRIBUTOS_TRASPASO then
    Result.NumeroAtributos := MAXIMO_ATRIBUTOS_TRASPASO;
  for iAtributo := 1 to Result.NumeroAtributos do
    Result.ValoresAtributos[iAtributo] := PartesSku[iAtributo];
end;

function LineasCargaDeRecuentoApp(
  ALecturas: TStrings;
  const ABuscarSku: TBuscarDatosSkuTraspaso;
  ADescartadas: TStrings): TLineasCargaTraspaso;
var
  Datos: TDatosSkuTraspaso;
  Valor: TValorRecuentoLote;
  iCuenta: Integer;
  iExistente: Integer;
  iLectura: Integer;
  sSku: string;
begin
  if not Assigned(ABuscarSku) then
    raise EArgumentNilException.Create('ABuscarSku');
  SetLength(Result, ALecturas.Count);
  iCuenta := 0;
  for iLectura := 0 to ALecturas.Count - 1 do
  begin
    sSku := ObtenerSkuRecuento(ALecturas, iLectura);
    Valor := LeerValorRecuentoLote(ALecturas.ValueFromIndex[iLectura]);
    if (sSku = '') or (not Valor.TieneCantidad) or
       (Valor.Cantidad <= TOLERANCIA_CANTIDAD) or
       (not ABuscarSku(sSku, Datos)) then
    begin
      if Assigned(ADescartadas) then
        ADescartadas.Add(
          sSku + ' (' + ALecturas.ValueFromIndex[iLectura] + ')');
    end
    else
    begin
      iExistente := IndiceLinea(Result, iCuenta, sSku, Valor.Lote);
      if iExistente >= 0 then
        Result[iExistente].Cantidad :=
          Result[iExistente].Cantidad + Valor.Cantidad
      else
      begin
        Result[iCuenta] := NuevaLinea(sSku, Datos, Valor);
        Inc(iCuenta);
      end;
    end;
  end;
  SetLength(Result, iCuenta);
end;

end.
