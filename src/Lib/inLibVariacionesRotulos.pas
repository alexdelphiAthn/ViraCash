{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVariacionesRotulos                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Rótulos que una pantalla muestra según el tipo de variación del           }
{    artículo (FZ-ISSUE-420): con «Tallas y colores» las columnas dicen        }
{    Color, Sistema tallas y Otro color; con «Aroma y medida», Aroma,          }
{    Medidas y Otro aroma. Los nombres salen de fza_variaciones_atributos      }
{    (NOMBRE_VA y NOMBRE_VISIBLE_VA) y de fza_variaciones (ROTULO_OTRO_VAR,    }
{    ESCOLOR_BASICO_VAR); aquí solo se decide qué atributo es el eje de        }
{    fila y cuál el pivote, y qué texto vale cuando falta alguno.              }
{******************************************************************************}
unit inLibVariacionesRotulos;

interface

type
  // Atributo de un tipo de variación tal como lo describe
  // fza_variaciones_atributos, sin dependencias de datos.
  TAtributoVariacionRotulo = record
    Id: string;
    Nombre: string;
    NombreVisible: string;
    Orden: Integer;
    // EJE_VA de fza_variaciones_atributos: 'S' = pestañas, '' = posición.
    EjeDeclarado: string;
  end;
  TAtributosVariacionRotulo = array of TAtributoVariacionRotulo;

  TRotulosVariacion = record
    CodigoVariacion: string;
    AtributoFila: string;
    AtributoPivote: string;
    // Columna del valor de fila de cada línea: Color, Aroma...
    EjeFila: string;
    // Nombre de un valor del pivote: Talla, Medida...
    EjePivote: string;
    // Selector de la colección del pivote: Sistema tallas, Medidas...
    SistemaPivote: string;
    // Botón que repite la línea con otro valor de fila: Otro color...
    OtroValorFila: string;
    EsColorBasico: Boolean;
    // False cuando el tipo de variación tiene un solo atributo («Solo
    // medida»): no hay eje de fila y la pantalla esconde su columna y el
    // botón de repetir la línea (FZ-ISSUE-451).
    TieneEjeFila: Boolean;
    // Tercera dimensión (fase 4): atributo en pestañas (la copa), su
    // nombre y los botones que repiten la línea con otro valor o con
    // todos. Sin pestañas, TienePestanas = False y el resto vacío.
    TienePestanas: Boolean;
    AtributoPestana: string;
    EjePestana: string;
    OtroValorPestana: string;
    TodosValoresPestana: string;
  end;

const
  ATRIBUTO_PIVOTE_TALLAS = 'TAL';
  ATRIBUTO_FILA_COLOR = 'CO';

// Rótulos de la variación histórica de ropa y calzado; valen también
// mientras la sesión aún no tiene tipo de variación.
function RotulosVariacionPorDefecto: TRotulosVariacion;
// El pivote es el último atributo por orden y código dentro del tipo;
// el eje de fila es el primero que no sea el pivote. Un nombre vacío cae
// al rótulo por defecto y, sin rótulo del botón, se forma «Otro <fila>».
function ConstruirRotulosVariacion(
  const ACodigoVariacion: string;
  const AAtributos: TAtributosVariacionRotulo;
  const ARotuloOtroValorFila: string;
  AEsColorBasico: Boolean): TRotulosVariacion;
// Rótulos de las columnas de atributos cuando la rejilla puede mezclar
// artículos de variaciones distintas (FZ-ISSUE-436): uno por posición del
// atributo en su variación, con los nombres distintos de esa posición
// unidos («Color / Aroma», «Talla / Medida»). APosiciones (desde 1) y
// ANombres van emparejados, en el orden en que se quieren ver.
function ComponerRotulosEjesGlobales(const APosiciones: TArray<Integer>;
  const ANombres: TArray<string>; AMaximo: Integer): TArray<string>;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  inLibEjesVariacion,
  inLibMsgCompras;

function RotulosVariacionPorDefecto: TRotulosVariacion;
begin
  Result := Default(TRotulosVariacion);
  Result.AtributoFila := ATRIBUTO_FILA_COLOR;
  Result.AtributoPivote := ATRIBUTO_PIVOTE_TALLAS;
  Result.EjeFila := SRotuloEjeFilaVariacionSesion;
  Result.EjePivote := SRotuloEjePivoteVariacionSesion;
  Result.SistemaPivote := SRotuloSistemaPivoteVariacionSesion;
  Result.OtroValorFila := Format(SRotuloOtroValorFilaVariacionSesion,
    [LowerCase(SRotuloEjeFilaVariacionSesion)]);
  Result.EsColorBasico := True;
  Result.TieneEjeFila := True;
end;

function OrdenarPorOrden(
  const AAtributos: TAtributosVariacionRotulo): TAtributosVariacionRotulo;
begin
  Result := Copy(AAtributos);
  TArray.Sort<TAtributoVariacionRotulo>(Result,
    TComparer<TAtributoVariacionRotulo>.Construct(
      function(const AIzquierda, ADerecha: TAtributoVariacionRotulo):
        Integer
      begin
        Result := AIzquierda.Orden - ADerecha.Orden;
        if Result = 0 then
          Result := CompareText(AIzquierda.Id, ADerecha.Id);
      end));
end;

function IndicePivote(
  const AAtributos: TAtributosVariacionRotulo): Integer;
begin
  Result := High(AAtributos);
end;

function IndiceFila(
  const AAtributos: TAtributosVariacionRotulo; APivote: Integer): Integer;
var
  iIndice: Integer;
begin
  Result := -1;
  for iIndice := High(AAtributos) downto 0 do
    if iIndice <> APivote then
      Result := iIndice;
end;

function ComponerRotulosEjesGlobales(const APosiciones: TArray<Integer>;
  const ANombres: TArray<string>; AMaximo: Integer): TArray<string>;
const
  SEPARADOR = ' / ';
var
  iFila: Integer;
  iPosicion: Integer;
  sNombre: string;
begin
  SetLength(Result, 0);
  for iFila := 0 to High(APosiciones) do
  begin
    iPosicion := APosiciones[iFila];
    sNombre := '';
    if iFila <= High(ANombres) then
      sNombre := Trim(ANombres[iFila]);
    if (iPosicion >= 1) and (iPosicion <= AMaximo) and (sNombre <> '') then
    begin
      if Length(Result) < iPosicion then
        SetLength(Result, iPosicion);
      if Result[iPosicion - 1] = '' then
        Result[iPosicion - 1] := sNombre
      else if not ContainsText(
        SEPARADOR + Result[iPosicion - 1] + SEPARADOR,
        SEPARADOR + sNombre + SEPARADOR) then
        Result[iPosicion - 1] := Result[iPosicion - 1] + SEPARADOR +
          sNombre;
    end;
  end;
end;

// El atributo que VI_VARIACIONES_EJES pone en pestañas, con la misma
// regla (inLibEjesVariacion); -1 si el tipo no tiene.
function IndicePestana(const AAtributos: TAtributosVariacionRotulo):
  Integer;
var
  aEjes: TAtributosEjeVariacion;
  aResultado: TArray<TEjeVariacion>;
  iIndice: Integer;
begin
  Result := -1;
  SetLength(aEjes, Length(AAtributos));
  for iIndice := 0 to High(AAtributos) do
  begin
    aEjes[iIndice].Id := AAtributos[iIndice].Id;
    aEjes[iIndice].Orden := AAtributos[iIndice].Orden;
    aEjes[iIndice].EjeDeclarado := AAtributos[iIndice].EjeDeclarado;
  end;
  aResultado := CalcularEjesVariacion(aEjes);
  for iIndice := 0 to High(aResultado) do
    if aResultado[iIndice] = evPestana then
      Result := iIndice;
end;

function TextoODefecto(const ATexto, ADefecto: string): string;
begin
  Result := Trim(ATexto);
  if Result = '' then
    Result := ADefecto;
end;

function ConstruirRotulosVariacion(
  const ACodigoVariacion: string;
  const AAtributos: TAtributosVariacionRotulo;
  const ARotuloOtroValorFila: string;
  AEsColorBasico: Boolean): TRotulosVariacion;
var
  aOrdenados: TAtributosVariacionRotulo;
  iFila: Integer;
  iPivote: Integer;
  iPestana: Integer;
begin
  Result := RotulosVariacionPorDefecto;
  Result.CodigoVariacion := Trim(ACodigoVariacion);
  Result.EsColorBasico := AEsColorBasico;
  aOrdenados := OrdenarPorOrden(AAtributos);
  iPivote := IndicePivote(aOrdenados);
  iFila := IndiceFila(aOrdenados, iPivote);
  // Sin atributos leídos no se sabe: se supone la variación de siempre.
  Result.TieneEjeFila := (Length(aOrdenados) = 0) or (iFila >= 0);
  if iPivote >= 0 then
  begin
    Result.AtributoPivote := TextoODefecto(aOrdenados[iPivote].Id,
      ATRIBUTO_PIVOTE_TALLAS);
    Result.EjePivote := TextoODefecto(aOrdenados[iPivote].Nombre,
      SRotuloEjePivoteVariacionSesion);
    Result.SistemaPivote := TextoODefecto(aOrdenados[iPivote].NombreVisible,
      Result.EjePivote);
  end;
  if iFila >= 0 then
  begin
    Result.AtributoFila := TextoODefecto(aOrdenados[iFila].Id,
      ATRIBUTO_FILA_COLOR);
    Result.EjeFila := TextoODefecto(aOrdenados[iFila].Nombre,
      SRotuloEjeFilaVariacionSesion);
  end;
  if not Result.TieneEjeFila then
    Result.AtributoFila := '';
  Result.OtroValorFila := TextoODefecto(ARotuloOtroValorFila,
    Format(SRotuloOtroValorFilaVariacionSesion,
      [LowerCase(Result.EjeFila)]));
  iPestana := IndicePestana(AAtributos);
  Result.TienePestanas := iPestana >= 0;
  if Result.TienePestanas then
  begin
    Result.AtributoPestana := AAtributos[iPestana].Id;
    Result.EjePestana := TextoODefecto(AAtributos[iPestana].Nombre,
      AAtributos[iPestana].Id);
    Result.OtroValorPestana := Format(SRotuloOtroValorPestanaSesion,
      [LowerCase(Result.EjePestana)]);
    Result.TodosValoresPestana := Format(SRotuloTodosValoresPestanaSesion,
      [LowerCase(Result.EjePestana)]);
  end;
end;

end.
