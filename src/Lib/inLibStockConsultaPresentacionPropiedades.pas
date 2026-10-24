{******************************************************************************}
{                                                                              }
{  Modulo:       inLibStockConsultaPresentacionPropiedades                     }
{    Tipo:       Colaborador de presentacion                                   }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Letrero de propiedades propias por color: recoge las propiedades fijadas  }
{    a nivel COLOR o SKU cuyo valor difiere del nivel articulo y las compone   }
{    ya formateadas. Estado puro: sin VCL y sin SQL.                           }
{******************************************************************************}
unit inLibStockConsultaPresentacionPropiedades;

interface

uses
  System.Generics.Collections;

type
  TPropiedadColorStock = record
    Color: string;
    Nombre: string;
    Nivel: string;
    TipoValor: string;
    ValorLista: string;
    ValorLibre: string;
    ValorListaArticulo: string;
    ValorLibreArticulo: string;
  end;

  TPropiedadesPorColorStock = class
  private
    FTextos: TDictionary<string, string>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Limpiar;
    procedure Agregar(const APropiedad: TPropiedadColorStock);
    function TieneColor(const AColor: string): Boolean;
    function TextoDe(const AColor: string): string;
  end;

function ValorPropiedadColorStock(
  const ATipoValor, AValorLista, AValorLibre: string): string;
function EntradaPropiedadColorStock(
  const ANombre, AValor, ANivel: string): string;
function LetreroPropiedadesColorStock(
  const AColor, ATexto: string): string;

implementation

uses
  System.StrUtils, System.SysUtils;

const
  SEPARADOR_PROPIEDADES_COLOR = '   ·   ';

// Valor mostrable segun el tipo de propiedad. Un booleano sin valor no
// aporta nada y se descarta arriba dejandolo vacio.
function ValorPropiedadColorStock(
  const ATipoValor, AValorLista, AValorLibre: string): string;
begin
  if SameText(ATipoValor, 'LISTA') then
    Result := Trim(AValorLista)
  else if SameText(ATipoValor, 'BOOLEANO') then
  begin
    if Trim(AValorLibre) = '' then
      Result := ''
    else if SameText(Trim(AValorLibre), 'S') then
      Result := 'Sí'
    else
      Result := 'No';
  end
  else
    Result := Trim(AValorLibre);
end;

function EntradaPropiedadColorStock(
  const ANombre, AValor, ANivel: string): string;
begin
  Result := Format('%s: %s (%s)',
    [ANombre, AValor, IfThen(SameText(ANivel, 'SKU'), 'SKU', 'color')]);
end;

function LetreroPropiedadesColorStock(
  const AColor, ATexto: string): string;
begin
  Result := Format('  %s →   %s', [AColor, ATexto]);
end;

constructor TPropiedadesPorColorStock.Create;
begin
  inherited Create;
  FTextos := TDictionary<string, string>.Create;
end;

destructor TPropiedadesPorColorStock.Destroy;
begin
  FreeAndNil(FTextos);
  inherited Destroy;
end;

procedure TPropiedadesPorColorStock.Limpiar;
begin
  FTextos.Clear;
end;

// Solo se acumula lo que aporta valor y difiere del nivel articulo. La
// misma propiedad puede llegar repetida por varias tallas del mismo
// color, por eso se deduplica antes de concatenar.
procedure TPropiedadesPorColorStock.Agregar(
  const APropiedad: TPropiedadColorStock);
var
  sAcumulado: string;
  sEntrada: string;
  sValor: string;
  sValorArticulo: string;
begin
  sValor := ValorPropiedadColorStock(
    APropiedad.TipoValor,
    APropiedad.ValorLista,
    APropiedad.ValorLibre);
  sValorArticulo := ValorPropiedadColorStock(
    APropiedad.TipoValor,
    APropiedad.ValorListaArticulo,
    APropiedad.ValorLibreArticulo);
  if (sValor <> '') and (not SameText(sValor, sValorArticulo)) then
  begin
    sEntrada := EntradaPropiedadColorStock(
      APropiedad.Nombre, sValor, APropiedad.Nivel);
    if FTextos.TryGetValue(APropiedad.Color, sAcumulado) then
    begin
      if Pos(sEntrada, sAcumulado) = 0 then
        FTextos[APropiedad.Color] := sAcumulado +
          SEPARADOR_PROPIEDADES_COLOR + sEntrada;
    end
    else
      FTextos.Add(APropiedad.Color, sEntrada);
  end;
end;

function TPropiedadesPorColorStock.TieneColor(
  const AColor: string): Boolean;
begin
  Result := FTextos.ContainsKey(AColor);
end;

function TPropiedadesPorColorStock.TextoDe(
  const AColor: string): string;
begin
  if not FTextos.TryGetValue(AColor, Result) then
    Result := '';
end;

end.
