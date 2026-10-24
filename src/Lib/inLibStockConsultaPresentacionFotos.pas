{******************************************************************************}
{                                                                              }
{  Modulo:       inLibStockConsultaPresentacionFotos                           }
{    Tipo:       Colaborador de presentacion                                   }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Estado de las pestanas de fotos relacionadas (familia, proveedor y        }
{    temporada): cache por dimension, filtros cruzados y disposicion en        }
{    rejilla de las tarjetas. Estado puro: sin VCL y sin SQL.                  }
{******************************************************************************}
unit inLibStockConsultaPresentacionFotos;

interface

uses
  inLibStockConsultaPersistenciaIntf;

const
  // Geometria de la rejilla de tarjetas de articulos relacionados.
  ANCHO_TARJETA_FOTO_STOCK  = 164;
  ALTO_TARJETA_FOTO_STOCK   = 238;
  MARGEN_TARJETA_FOTO_STOCK = 12;
  TOP_TARJETAS_FOTO_STOCK   = 48;

type
  TEstadoFotosRelacionadas = class
  private
    FCargadas: array[TDimensionFotos] of Boolean;
    FArticulos: array[TDimensionFotos] of string;
    FFiltros: array[TDimensionFotos] of TDimensionesFotos;
    FFiltrosCache: array[TDimensionFotos] of TDimensionesFotos;
    function GetCargada(ADimension: TDimensionFotos): Boolean;
    function GetFiltros(
      ADimension: TDimensionFotos): TDimensionesFotos;
  public
    constructor Create;
    procedure Invalidar;
    procedure Reiniciar(ADimension: TDimensionFotos);
    procedure IniciarCarga(ADimension: TDimensionFotos;
      const ACodigoArticulo: string);
    procedure MarcarCargada(ADimension: TDimensionFotos);
    procedure AlternarFiltro(
      ADimension, AFiltro: TDimensionFotos);
    function DebeRecargar(ADimension: TDimensionFotos;
      const ACodigoArticulo: string): Boolean;
    function FiltrosSecundarios(
      ADimension: TDimensionFotos): TArray<TDimensionFotos>;
    function FiltroActivo(
      ADimension, AFiltro: TDimensionFotos): Boolean;
    property Cargadas[ADimension: TDimensionFotos]: Boolean
      read GetCargada;
    property Filtros[ADimension: TDimensionFotos]: TDimensionesFotos
      read GetFiltros;
  end;

function NombreDimensionFotos(ADimension: TDimensionFotos): string;
function EtiquetaFiltroFotos(
  ADimension: TDimensionFotos; AActivo: Boolean): string;
function ColumnasTarjetasFotos(AAnchoDisponible: Integer): Integer;
procedure PosicionTarjetaFotos(AIndice, AColumnas: Integer;
  out AX, AY: Integer);

implementation

uses
  System.SysUtils;

function NombreDimensionFotos(ADimension: TDimensionFotos): string;
begin
  case ADimension of
    dfFamilia:
      Result := 'Familia';
    dfProveedor:
      Result := 'Proveedor';
    dfTemporada:
      Result := 'Temporada';
  else
    Result := '';
  end;
end;

function EtiquetaFiltroFotos(
  ADimension: TDimensionFotos; AActivo: Boolean): string;
begin
  if AActivo then
    Result := '[X] '
  else
    Result := '[ ] ';
  Result := Result + NombreDimensionFotos(ADimension);
end;

function ColumnasTarjetasFotos(AAnchoDisponible: Integer): Integer;
begin
  Result := (AAnchoDisponible - MARGEN_TARJETA_FOTO_STOCK) div
            (ANCHO_TARJETA_FOTO_STOCK + MARGEN_TARJETA_FOTO_STOCK);
  if Result < 1 then
    Result := 1;
end;

procedure PosicionTarjetaFotos(AIndice, AColumnas: Integer;
  out AX, AY: Integer);
begin
  if AColumnas < 1 then
    AColumnas := 1;
  AX := MARGEN_TARJETA_FOTO_STOCK + (AIndice mod AColumnas) *
        (ANCHO_TARJETA_FOTO_STOCK + MARGEN_TARJETA_FOTO_STOCK);
  AY := TOP_TARJETAS_FOTO_STOCK + MARGEN_TARJETA_FOTO_STOCK +
        (AIndice div AColumnas) *
        (ALTO_TARJETA_FOTO_STOCK + MARGEN_TARJETA_FOTO_STOCK);
end;

constructor TEstadoFotosRelacionadas.Create;
var
  Dimension: TDimensionFotos;
begin
  inherited Create;
  for Dimension := Low(TDimensionFotos) to High(TDimensionFotos) do
  begin
    FCargadas[Dimension] := False;
    FArticulos[Dimension] := '';
    FFiltros[Dimension] := [];
    FFiltrosCache[Dimension] := [];
  end;
end;

function TEstadoFotosRelacionadas.GetCargada(
  ADimension: TDimensionFotos): Boolean;
begin
  Result := FCargadas[ADimension];
end;

function TEstadoFotosRelacionadas.GetFiltros(
  ADimension: TDimensionFotos): TDimensionesFotos;
begin
  Result := FFiltros[ADimension];
end;

// Al cambiar de articulo se invalida la cache de las tres dimensiones,
// pero se conservan los filtros elegidos por el usuario.
procedure TEstadoFotosRelacionadas.Invalidar;
var
  Dimension: TDimensionFotos;
begin
  for Dimension := Low(TDimensionFotos) to High(TDimensionFotos) do
  begin
    FCargadas[Dimension] := False;
    FArticulos[Dimension] := '';
  end;
end;

procedure TEstadoFotosRelacionadas.Reiniciar(
  ADimension: TDimensionFotos);
begin
  FFiltros[ADimension] := [];
  FCargadas[ADimension] := False;
end;

procedure TEstadoFotosRelacionadas.IniciarCarga(
  ADimension: TDimensionFotos; const ACodigoArticulo: string);
begin
  FCargadas[ADimension] := False;
  FArticulos[ADimension] := ACodigoArticulo;
  FFiltrosCache[ADimension] := FFiltros[ADimension];
end;

procedure TEstadoFotosRelacionadas.MarcarCargada(
  ADimension: TDimensionFotos);
begin
  FCargadas[ADimension] := True;
end;

procedure TEstadoFotosRelacionadas.AlternarFiltro(
  ADimension, AFiltro: TDimensionFotos);
begin
  if AFiltro in FFiltros[ADimension] then
    Exclude(FFiltros[ADimension], AFiltro)
  else
    Include(FFiltros[ADimension], AFiltro);
  FCargadas[ADimension] := False;
end;

function TEstadoFotosRelacionadas.FiltroActivo(
  ADimension, AFiltro: TDimensionFotos): Boolean;
begin
  Result := AFiltro in FFiltros[ADimension];
end;

// Se recarga si nunca se cargo, si cambio el articulo o si el usuario
// modifico los filtros cruzados desde la ultima carga.
function TEstadoFotosRelacionadas.DebeRecargar(
  ADimension: TDimensionFotos;
  const ACodigoArticulo: string): Boolean;
begin
  Result := (not FCargadas[ADimension]) or
            (not SameText(FArticulos[ADimension], ACodigoArticulo)) or
            (FFiltrosCache[ADimension] <> FFiltros[ADimension]);
end;

// Cada pestana ofrece como filtro cruzado las otras dos dimensiones.
function TEstadoFotosRelacionadas.FiltrosSecundarios(
  ADimension: TDimensionFotos): TArray<TDimensionFotos>;
begin
  case ADimension of
    dfFamilia:
      Result := [dfProveedor, dfTemporada];
    dfProveedor:
      Result := [dfFamilia, dfTemporada];
  else
    Result := [dfFamilia, dfProveedor];
  end;
end;

end.
