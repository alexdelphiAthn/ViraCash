{******************************************************************************}
{                                                                              }
{  Modulo:       inLibStockConsultaPresentacionPivote                          }
{    Tipo:       Colaborador de presentacion                                   }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Decide la solicitud del pivote y el juego de columnas que la rejilla     }
{    debe materializar. Estado puro: sin VCL y sin SQL, para poder            }
{    probar el mapa de columnas y la lectura de la talla enfocada.             }
{******************************************************************************}
unit inLibStockConsultaPresentacionPivote;

interface

uses
  inLibStockConsultaPersistenciaIntf;

const
  CAMPO_GRUPO_PIVOTE_STOCK  = 'GRUPO';
  CAMPO_ESTADO_PIVOTE_STOCK = 'ESTADO_NUM';
  CAMPO_TOTAL_PIVOTE_STOCK  = 'TOTAL';
  PREFIJO_CAMPO_TALLA_STOCK = 'T';
  ANCHO_COL_COLOR_STOCK     = 180;
  ANCHO_COL_ALMACEN_STOCK   = 160;
  ANCHO_COL_ESTADO_STOCK    = 130;
  ANCHO_COL_TALLA_STOCK     = 100;
  ANCHO_COL_TOTAL_STOCK     = 100;

type
  TClaseColumnaPivoteStock = (
    cpsGrupo,
    cpsEstado,
    cpsTalla,
    cpsTotal);

  TDefinicionColumnaPivote = record
    Clase: TClaseColumnaPivoteStock;
    Titulo: string;
    Campo: string;
    Ancho: Integer;
  end;
  TDefinicionesColumnasPivote = TArray<TDefinicionColumnaPivote>;

function CampoTallaPivoteStock(AIndice: Integer): string;
function DefinirColumnasPivoteStock(
  const ATallas: TArray<TInfoColumna>;
  APorColor, AModoTodo: Boolean;
  const ATituloGrupo, ATituloEstado,
        ATituloTotal: string): TDefinicionesColumnasPivote;
function ComponerSolicitudPivoteStock(
  const ACodigoArticulo: string;
  AEstado: TEstadoStock;
  AModoDesglosado, APorColor, AOcultarCeros: Boolean;
  const AAlmacenes, AColores: TArray<string>): TSolicitudPivoteStock;
function TallaDeColumnaPivoteStock(
  const ANombreCampo: string;
  const ATallas: TArray<TInfoColumna>;
  out ATalla: string): Boolean;

implementation

uses
  System.StrUtils, System.SysUtils;

function CampoTallaPivoteStock(AIndice: Integer): string;
begin
  Result := Format('%s%d', [PREFIJO_CAMPO_TALLA_STOCK, AIndice]);
end;

// Las tallas van siempre como columnas dinamicas T0..Tn-1; la columna de
// grupo es el color o el almacen y la de estado solo existe en modo
// "Todo a la vez", donde cada fila se desdobla por estado.
function DefinirColumnasPivoteStock(
  const ATallas: TArray<TInfoColumna>;
  APorColor, AModoTodo: Boolean;
  const ATituloGrupo, ATituloEstado,
        ATituloTotal: string): TDefinicionesColumnasPivote;
var
  i: Integer;
  iColumna: Integer;
  procedure Agregar(AClase: TClaseColumnaPivoteStock;
    const ATitulo, ACampo: string; AAncho: Integer);
  begin
    SetLength(Result, iColumna + 1);
    Result[iColumna].Clase := AClase;
    Result[iColumna].Titulo := ATitulo;
    Result[iColumna].Campo := ACampo;
    Result[iColumna].Ancho := AAncho;
    Inc(iColumna);
  end;
begin
  SetLength(Result, 0);
  iColumna := 0;
  if APorColor then
    Agregar(cpsGrupo, ATituloGrupo, CAMPO_GRUPO_PIVOTE_STOCK,
      ANCHO_COL_COLOR_STOCK)
  else
    Agregar(cpsGrupo, ATituloGrupo, CAMPO_GRUPO_PIVOTE_STOCK,
      ANCHO_COL_ALMACEN_STOCK);
  if AModoTodo then
    Agregar(cpsEstado, ATituloEstado, CAMPO_ESTADO_PIVOTE_STOCK,
      ANCHO_COL_ESTADO_STOCK);
  for i := 0 to High(ATallas) do
    Agregar(cpsTalla, ATallas[i].Texto, CampoTallaPivoteStock(i),
      ANCHO_COL_TALLA_STOCK);
  Agregar(cpsTotal, ATituloTotal, CAMPO_TOTAL_PIVOTE_STOCK,
    ANCHO_COL_TOTAL_STOCK);
end;

function ComponerSolicitudPivoteStock(
  const ACodigoArticulo: string;
  AEstado: TEstadoStock;
  AModoDesglosado, APorColor, AOcultarCeros: Boolean;
  const AAlmacenes, AColores: TArray<string>): TSolicitudPivoteStock;
begin
  Result := Default(TSolicitudPivoteStock);
  Result.CodigoArticulo := ACodigoArticulo;
  Result.Estado := AEstado;
  Result.ModoDesglosado := AModoDesglosado;
  Result.PorColor := APorColor;
  Result.OcultarCeros := AOcultarCeros;
  Result.Almacenes := AAlmacenes;
  Result.Colores := AColores;
end;

// Traduce el nombre de campo de la columna enfocada a codigo de talla.
// Un articulo sin tallas solo tiene la columna TOTAL, que representa la
// unica talla vacia.
function TallaDeColumnaPivoteStock(
  const ANombreCampo: string;
  const ATallas: TArray<TInfoColumna>;
  out ATalla: string): Boolean;
var
  iTalla: Integer;
begin
  Result := False;
  ATalla := '';
  iTalla := -1;
  if StartsText(PREFIJO_CAMPO_TALLA_STOCK, ANombreCampo) and
     TryStrToInt(Copy(ANombreCampo, 2, MaxInt), iTalla) and
     (iTalla >= 0) and (iTalla <= High(ATallas)) then
  begin
    ATalla := ATallas[iTalla].Codigo;
    Result := True;
  end
  else if SameText(ANombreCampo, CAMPO_TOTAL_PIVOTE_STOCK) and
          (Length(ATallas) = 0) then
  begin
    Result := True;
  end;
end;

end.
