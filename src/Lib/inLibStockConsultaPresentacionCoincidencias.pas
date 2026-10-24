{******************************************************************************}
{                                                                              }
{  Modulo:       inLibStockConsultaPresentacionCoincidencias                   }
{    Tipo:       Colaborador de presentacion                                   }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Lista de coincidencias que se ofrece cuando una entrada de texto          }
{    resuelve varios articulos: deduplicacion por articulo, texto visible y    }
{    medidas del desplegable. Estado puro: sin VCL y sin SQL.                  }
{******************************************************************************}
unit inLibStockConsultaPresentacionCoincidencias;

interface

uses
  inLibStockConsultaEntradaIntf;

const
  MAX_FILAS_COINCIDENCIAS_STOCK = 15;
  MAX_ANCHO_COINCIDENCIAS_STOCK = 620;

type
  TCoincidenciasArticuloStock = class
  private
    FCodigos: TArray<string>;
    FSkus: TArray<string>;
    FTextos: TArray<string>;
    function GetCuenta: Integer;
    function GetCodigo(AIndice: Integer): string;
    function GetSku(AIndice: Integer): string;
    function GetTexto(AIndice: Integer): string;
    function IndiceDeCodigo(const ACodigo: string): Integer;
  public
    procedure Limpiar;
    procedure Cargar(const ACoincidencias: TCoincidenciasEntradaStock);
    function EsIndiceValido(AIndice: Integer): Boolean;
    function FilasDesplegable: Integer;
    property Cuenta: Integer read GetCuenta;
    property Codigos[AIndice: Integer]: string read GetCodigo;
    property Skus[AIndice: Integer]: string read GetSku;
    property Textos[AIndice: Integer]: string read GetTexto;
  end;

function DescribirCoincidenciaStock(
  const ACoincidencia: TCoincidenciaEntradaStock): string;
function AnchoDesplegableCoincidencias(
  AAnchoDisponible, AAnchoMinimo: Integer): Integer;

implementation

uses
  System.SysUtils;

// Texto visible del desplegable: "ART / SKU - descripcion - proveedor
// (ref. referencia)", omitiendo los tramos vacios.
function DescribirCoincidenciaStock(
  const ACoincidencia: TCoincidenciaEntradaStock): string;
begin
  Result := ACoincidencia.CodigoArticulo;
  if Trim(ACoincidencia.CodigoSku) <> '' then
    Result := Result + ' / ' + ACoincidencia.CodigoSku;
  if Trim(ACoincidencia.Descripcion) <> '' then
    Result := Result + ' - ' + ACoincidencia.Descripcion;
  if Trim(ACoincidencia.Proveedor) <> '' then
    Result := Result + ' - ' + ACoincidencia.Proveedor;
  if Trim(ACoincidencia.ReferenciaProveedor) <> '' then
    Result := Result + ' (ref. ' + ACoincidencia.ReferenciaProveedor + ')';
end;

function AnchoDesplegableCoincidencias(
  AAnchoDisponible, AAnchoMinimo: Integer): Integer;
begin
  Result := AAnchoDisponible;
  if Result > MAX_ANCHO_COINCIDENCIAS_STOCK then
    Result := MAX_ANCHO_COINCIDENCIAS_STOCK;
  if Result < AAnchoMinimo then
    Result := AAnchoMinimo;
end;

function TCoincidenciasArticuloStock.GetCuenta: Integer;
begin
  Result := Length(FCodigos);
end;

function TCoincidenciasArticuloStock.GetCodigo(
  AIndice: Integer): string;
begin
  if EsIndiceValido(AIndice) then
    Result := FCodigos[AIndice]
  else
    Result := '';
end;

function TCoincidenciasArticuloStock.GetSku(AIndice: Integer): string;
begin
  if EsIndiceValido(AIndice) then
    Result := FSkus[AIndice]
  else
    Result := '';
end;

function TCoincidenciasArticuloStock.GetTexto(
  AIndice: Integer): string;
begin
  if EsIndiceValido(AIndice) then
    Result := FTextos[AIndice]
  else
    Result := '';
end;

function TCoincidenciasArticuloStock.IndiceDeCodigo(
  const ACodigo: string): Integer;
var
  i: Integer;
begin
  Result := -1;
  i := 0;
  while (Result < 0) and (i < Length(FCodigos)) do
  begin
    if FCodigos[i] = ACodigo then
      Result := i;
    Inc(i);
  end;
end;

function TCoincidenciasArticuloStock.EsIndiceValido(
  AIndice: Integer): Boolean;
begin
  Result := (AIndice >= 0) and (AIndice < Length(FCodigos));
end;

procedure TCoincidenciasArticuloStock.Limpiar;
begin
  SetLength(FCodigos, 0);
  SetLength(FSkus, 0);
  SetLength(FTextos, 0);
end;

// Una fila por articulo: el primer SKU que aparece manda y las repeticiones
// del mismo articulo (varios SKU) no generan entradas nuevas.
procedure TCoincidenciasArticuloStock.Cargar(
  const ACoincidencias: TCoincidenciasEntradaStock);
var
  Coincidencia: TCoincidenciaEntradaStock;
  iFila: Integer;
begin
  Limpiar;
  for Coincidencia in ACoincidencias do
  begin
    if IndiceDeCodigo(Coincidencia.CodigoArticulo) < 0 then
    begin
      iFila := Length(FCodigos);
      SetLength(FCodigos, iFila + 1);
      SetLength(FSkus, iFila + 1);
      SetLength(FTextos, iFila + 1);
      FCodigos[iFila] := Coincidencia.CodigoArticulo;
      FSkus[iFila] := Coincidencia.CodigoSku;
      FTextos[iFila] := DescribirCoincidenciaStock(Coincidencia);
    end;
  end;
end;

function TCoincidenciasArticuloStock.FilasDesplegable: Integer;
begin
  Result := Length(FCodigos);
  if Result > MAX_FILAS_COINCIDENCIAS_STOCK then
    Result := MAX_FILAS_COINCIDENCIAS_STOCK;
end;

end.
