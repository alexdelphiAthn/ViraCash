{******************************************************************************}
{                                                                              }
{  Módulo:       inLibModoTallasModelo                                         }
{    Tipo:       Librería (dominio)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modelo del modo tallas: composición y descomposición de SKU, atributos    }
{    y conjunto pivote, clave de consolidación, unidades del documento e       }
{    invariante de unidades. Sin UI, sin UniDAC y sin datasets.                }
{******************************************************************************}
unit inLibModoTallasModelo;

interface

uses
  System.SysUtils, System.StrUtils, System.Generics.Collections,
  inLibArticulosAtributosIntf, inLibModoTallasIntf;

type
  TModeloTallas = class
  private
    FLookup: IArticulosAtributosLookup;
    FPersistencia: IPersistenciaModeloTallas;
    FSelector: ISelectorValorAtributo;
    FRegistro: TRegistroTallas;
    procedure Registrar(const ATexto: string);
    function ValorNoTalla(const ACodArt, ANombreAtributo: string;
      AIndice: Integer; const APartes: TArray<string>;
      ASilencioso: Boolean): string;
  public
    constructor Create(const ALookup: IArticulosAtributosLookup;
      const APersistencia: IPersistenciaModeloTallas;
      const ASelector: ISelectorValorAtributo;
      ARegistro: TRegistroTallas);
    destructor Destroy; override;
    // ---- funciones puras ----
    // SKU de una linea: articulo + atributos en su orden, con la talla
    // ATalla insertada en la posicion AOrdTalla (0-based).
    class function ComponerSkuLinea(const AArt: string;
      const AVal: TValoresAttrTallas; AOrdTalla: Integer;
      const ATalla: string): string; static;
    // Trocea un SKU cerrado ART/VAL1/VAL2 en sus valores; nil si el SKU
    // no pertenece al articulo o no tiene variacion.
    class function PartesDeSku(const AArt,
      ASku: string): TArray<string>; static;
    // Último atributo de la lista ordenada del tipo de variación.
    class function EsAtributoTalla(
      const AAtributos: TArray<TArticuloAtributo>;
      AIndice: Integer): Boolean; static;
    class function ValorTallaDePartes(const APartes: TArray<string>;
      AOrdenTalla: Integer): string; static;
    class function IdsDeAvs(
      const AAvs: TArray<TArticuloAtributoValor>)
      : TArray<Integer>; static;
    // Clave de consolidacion de una linea. En DISTRIBUIDO el almacen NO
    // entra: la linea es unica por articulo+color y el reparto por
    // almacen vive en las celdas (modelo sesiones). El precio si entra
    // cuando el documento lo expone: dos lineas del mismo articulo con
    // precio distinto no fusionan.
    class function ClaveConsolidacion(ADistribuido: Boolean;
      const AArticulo, AAlmacen: string;
      const AValores: TValoresAttrTallas; ATienePrecio: Boolean;
      APrecio: Double): string; static;
    // Unidades totales del documento con formula estable en ambos
    // formatos: SUM(celdas) + CANTIDAD de las lineas SIN celdas. Las
    // lineas pivotadas no aportan su CANTIDAD (es un total derivado).
    // Es el invariante que toda conversion debe conservar.
    class function UnidadesDocumento(
      const ATotales: TArray<TTotalLineaTallas>;
      const ACantidades: TArray<TCantidadLineaTallas>): Double; static;
    // Compara unidades antes/despues de una conversion y lanza
    // excepcion si no cuadran: el try/except del llamador hace rollback
    // y el documento queda intacto.
    class procedure ComprobarInvarianteUnidades(const AContexto: string;
      AAntes, ADespues: Double; ARegistro: TRegistroTallas); static;
    // ---- consultas con catalogo ----
    // Conserva el sistema asignado; el grid anade las tallas externas.
    function ResolverConjuntoPivote(const ACodArt: string;
      AAsignado, AOrdenAtributo: Integer): Integer;
    // Calcula (SIN escribir en el cds) valores y nombres de atributos
    // no talla, el conjunto pivote y el indice del atributo talla.
    // APartes: valores que trajo el SKU (prioridad sobre la paleta).
    function CalcularAtributosLinea(const ACodArt: string;
      const APartes: TArray<string>;
      ASilencioso: Boolean): TAtributosLineaTallas;
    // ID_AV de la talla AValor del articulo (0 si no existe).
    function IdAvDeTalla(const ACodArt: string; AOrdenTalla: Integer;
      const AValor: string): Integer;
    // Posicion (0-based) y nombre del atributo talla del articulo.
    // AOrden = -1 cuando el articulo no tiene atributo de talla.
    procedure OrdenYNombreTalla(const ACodArt: string;
      out AOrden: Integer; out ANombre: string);
  end;

implementation

uses
  inLibMsgArticulos;

constructor TModeloTallas.Create(
  const ALookup: IArticulosAtributosLookup;
  const APersistencia: IPersistenciaModeloTallas;
  const ASelector: ISelectorValorAtributo;
  ARegistro: TRegistroTallas);
begin
  inherited Create;
  FLookup := ALookup;
  FPersistencia := APersistencia;
  FSelector := ASelector;
  FRegistro := ARegistro;
end;

destructor TModeloTallas.Destroy;
begin
  FSelector := nil;
  FPersistencia := nil;
  FLookup := nil;
  inherited;
end;

procedure TModeloTallas.Registrar(const ATexto: string);
begin
  if Assigned(FRegistro) then
    FRegistro(ATexto);
end;

class function TModeloTallas.ComponerSkuLinea(const AArt: string;
  const AVal: TValoresAttrTallas; AOrdTalla: Integer;
  const ATalla: string): string;
var
  i: Integer;
begin
  Result := AArt;
  for i := 1 to 5 do
  begin
    if (i - 1) = AOrdTalla then
      Result := Result + '/' + ATalla
    else if AVal[i] <> '' then
      Result := Result + '/' + AVal[i];
  end;
end;

class function TModeloTallas.PartesDeSku(const AArt,
  ASku: string): TArray<string>;
begin
  Result := nil;
  if (ASku <> '') and StartsText(AArt + '/', ASku) then
    Result := Copy(ASku, Length(AArt) + 2, MaxInt).Split(['/']);
end;

class function TModeloTallas.EsAtributoTalla(
  const AAtributos: TArray<TArticuloAtributo>; AIndice: Integer): Boolean;
begin
  Result := (AIndice >= 0) and (AIndice = High(AAtributos));
end;

class function TModeloTallas.ValorTallaDePartes(
  const APartes: TArray<string>; AOrdenTalla: Integer): string;
begin
  Result := '';
  if (AOrdenTalla >= 0) and (AOrdenTalla <= High(APartes)) then
    Result := Trim(APartes[AOrdenTalla]);
end;

class function TModeloTallas.IdsDeAvs(
  const AAvs: TArray<TArticuloAtributoValor>): TArray<Integer>;
var
  i: Integer;
begin
  SetLength(Result, Length(AAvs));
  for i := 0 to High(AAvs) do
    Result[i] := AAvs[i].IdValor;
end;

class function TModeloTallas.ClaveConsolidacion(ADistribuido: Boolean;
  const AArticulo, AAlmacen: string;
  const AValores: TValoresAttrTallas; ATienePrecio: Boolean;
  APrecio: Double): string;
var
  i: Integer;
begin
  if ADistribuido then
    Result := AArticulo + '|'
  else
    Result := AArticulo + '|' + UpperCase(AAlmacen);
  for i := 1 to 5 do
    Result := Result + '|' + UpperCase(AValores[i]);
  if ATienePrecio then
    Result := Result + '|' +
      FloatToStrF(APrecio, ffGeneral, 15, 4);
end;

class function TModeloTallas.UnidadesDocumento(
  const ATotales: TArray<TTotalLineaTallas>;
  const ACantidades: TArray<TCantidadLineaTallas>): Double;
var
  ConCeldas: TDictionary<Integer, Boolean>;
  i: Integer;
begin
  Result := 0;
  ConCeldas := TDictionary<Integer, Boolean>.Create;
  try
    for i := 0 to High(ATotales) do
    begin
      ConCeldas.AddOrSetValue(ATotales[i].Linea, True);
      Result := Result + ATotales[i].Total;
    end;
    // Lineas sin celdas (escalares o sin fusionar): su cantidad vive en
    // la propia linea.
    for i := 0 to High(ACantidades) do
    begin
      if not ConCeldas.ContainsKey(ACantidades[i].Linea) then
        Result := Result + ACantidades[i].Cantidad;
    end;
  finally
    FreeAndNil(ConCeldas);
  end;
end;

class procedure TModeloTallas.ComprobarInvarianteUnidades(
  const AContexto: string; AAntes, ADespues: Double;
  ARegistro: TRegistroTallas);
begin
  if Abs(AAntes - ADespues) > 0.001 then
  begin
    if Assigned(ARegistro) then
      ARegistro(Format('ModoTallas.%s: INVARIANTE ROTO unidades ' +
                       'antes=%.4f despues=%.4f; se deshace la ' +
                       'conversion', [AContexto, AAntes, ADespues]));
    raise Exception.CreateFmt(SErrorInvarianteUnidadesTallas,
      [AContexto, AAntes, ADespues]);
  end;
end;

function TModeloTallas.ResolverConjuntoPivote(const ACodArt: string;
  AAsignado, AOrdenAtributo: Integer): Integer;
var
  Avs: TArray<TArticuloAtributoValor>;
  Ids: TArray<Integer>;
begin
  Result := AAsignado;
  // El sistema asignado conserva sus posiciones. El gestor completa
  // sus columnas con las tallas del articulo que no esten en el.
  if Result = 0 then
  begin
    Avs := FLookup.ObtenerAvsEnSkus(ACodArt, AOrdenAtributo);
    Ids := IdsDeAvs(Avs);
    Result := FPersistencia.BuscarConjuntoParaAvs(Ids);
    Registrar(Format('ModoTallas: sistema inferido para %s = %d',
      [ACodArt, Result]));
  end;
end;

function TModeloTallas.ValorNoTalla(
  const ACodArt, ANombreAtributo: string; AIndice: Integer;
  const APartes: TArray<string>; ASilencioso: Boolean): string;
var
  Avs: TArray<TArticuloAtributoValor>;
  Valores: TArray<string>;
  j: Integer;
begin
  Result := '';
  // Prioridad 1: el valor vino en el SKU leido.
  if (AIndice <= High(APartes)) and (Trim(APartes[AIndice]) <> '') then
    Result := Trim(APartes[AIndice])
  else
  begin
    // Prioridad 2: unico valor posible se fija solo; si hay varios y no
    // vamos en silencio, se pide al selector visual.
    Avs := FLookup.ObtenerAvsEnSkus(ACodArt, AIndice + 1);
    if Length(Avs) = 1 then
      Result := Avs[0].Valor
    else if (Length(Avs) > 1) and (not ASilencioso) and
            Assigned(FSelector) then
    begin
      SetLength(Valores, Length(Avs));
      for j := 0 to High(Avs) do
        Valores[j] := Avs[j].Valor;
      if not FSelector.Seleccionar(ANombreAtributo, Valores,
                                   Result) then
        Result := '';
    end;
  end;
end;

function TModeloTallas.CalcularAtributosLinea(const ACodArt: string;
  const APartes: TArray<string>;
  ASilencioso: Boolean): TAtributosLineaTallas;
var
  Atribs: TArray<TArticuloAtributo>;
  i: Integer;
begin
  Result := Default(TAtributosLineaTallas);
  Result.OrdenTalla := -1;
  Atribs := FLookup.ObtenerAtributos(ACodArt);
  for i := 0 to High(Atribs) do
  begin
    if EsAtributoTalla(Atribs, i) then
    begin
      Result.OrdenTalla := i;
      Result.ConjuntoTalla := ResolverConjuntoPivote(
        ACodArt, Atribs[i].IdConjunto, i + 1);
    end
    else if i < 5 then
    begin
      Result.Valores[i + 1] := ValorNoTalla(ACodArt,
        Atribs[i].NombreAtributo, i, APartes, ASilencioso);
      Result.Nombres[i + 1] := Atribs[i].NombreAtributo;
    end;
  end;
end;

function TModeloTallas.IdAvDeTalla(const ACodArt: string;
  AOrdenTalla: Integer; const AValor: string): Integer;
var
  Avs: TArray<TArticuloAtributoValor>;
  i: Integer;
begin
  Result := 0;
  if (AOrdenTalla >= 0) and (AValor <> '') then
  begin
    Avs := FLookup.ObtenerAvsEnSkus(ACodArt, AOrdenTalla + 1);
    for i := 0 to High(Avs) do
      if SameText(Avs[i].Valor, AValor) then
        Result := Avs[i].IdValor;
  end;
end;

procedure TModeloTallas.OrdenYNombreTalla(const ACodArt: string;
  out AOrden: Integer; out ANombre: string);
var
  Atribs: TArray<TArticuloAtributo>;
  i: Integer;
begin
  AOrden := -1;
  ANombre := '';
  Atribs := FLookup.ObtenerAtributos(ACodArt);
  for i := 0 to High(Atribs) do
  begin
    if EsAtributoTalla(Atribs, i) then
    begin
      AOrden := i;
      ANombre := Atribs[i].NombreAtributo;
    end;
  end;
end;

end.
