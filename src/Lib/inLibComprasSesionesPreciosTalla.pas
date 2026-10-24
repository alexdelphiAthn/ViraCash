{******************************************************************************}
{                                                                              }
{  Módulo:       inLibComprasSesionesPreciosTalla                              }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       22/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Patrón de precios de un artículo de una sesión de compra (FZ-ISSUE-638):  }
{    a partir del coste y el PVP de cada SKU calcula las filas de tarifa       }
{    mínimas (general, ART/*/TALLA, ART/COLOR y SKU exacto) que, resueltas     }
{    con la prioridad vigente, devuelven el precio tecleado de cada SKU.       }
{******************************************************************************}
unit inLibComprasSesionesPreciosTalla;

interface

type
  // Un SKU de la sesión con su coste y su PVP efectivos (los de la talla
  // si se teclearon, si no los de la línea).
  TPrecioSkuSesion = record
    CodigoSku: string;
    // ART/COLOR, como el prefijo del SKU; vacío si no tiene color.
    ClaveColor: string;
    // Valor del eje pivote tal cual (fza_atributos_valores.AV).
    Talla: string;
    Coste: Double;
    Pvp: Double;
  end;
  TPreciosSkuSesion = TArray<TPrecioSkuSesion>;

  // Fila de fza_articulos_tarifas: Clave es CODIGO_UNIDAD_ARTTAR ('' para
  // la general del artículo).
  TFilaPrecioTarifa = record
    Clave: string;
    Coste: Double;
    Pvp: Double;
  end;
  TFilasPrecioTarifa = TArray<TFilaPrecioTarifa>;

  TArticuloPreciosTarifa = record
    CodigoArticulo: string;
    Filas: TFilasPrecioTarifa;
    // Ya tiene filas vigentes en la tarifa de la sesión.
    TieneVigentes: Boolean;
  end;
  TArticulosPreciosTarifa = TArray<TArticuloPreciosTarifa>;

  // Celda (color y talla) de una línea de la sesión con su coste y su PVP
  // propios; sin ellos hereda los de la línea.
  TPrecioCeldaSesion = record
    IdFila: Integer;
    IdAvPivot: Integer;
    Color: string;
    Talla: string;
    TieneCoste: Boolean;
    Coste: Double;
    TienePvp: Boolean;
    Pvp: Double;
  end;
  TPreciosCeldasSesion = TArray<TPrecioCeldaSesion>;

function ClaveTallaTarifa(const ACodigoArticulo, ATalla: string): string;
// Índice de la fila que aplica al SKU con la prioridad de
// UniDataTarifasPrecioSql (SKU > ART/*/TALLA > ART/COLOR > artículo);
// -1 si ninguna.
function ResolverFilaPrecioTarifa(const ACodigoArticulo: string;
  const AFilas: TFilasPrecioTarifa; const ASku: TPrecioSkuSesion): Integer;
// Filas que hay que grabar. AReferencia lleva el coste y el PVP de la
// línea (desempate de la fila general). AVigentes son las filas que
// seguirán vigentes en la tarifa y que no se sustituyen: cuentan en la
// comprobación final. La primera fila devuelta es siempre la general.
function CalcularFilasPrecioTarifa(const ACodigoArticulo: string;
  const APrecios: TPreciosSkuSesion;
  const AReferencia: TFilaPrecioTarifa;
  const AVigentes: TFilasPrecioTarifa): TFilasPrecioTarifa;
// Hay algo más que la fila general: precios por talla, color o SKU.
function TienePreciosPorTalla(const AFilas: TFilasPrecioTarifa): Boolean;
// «ZINF00001: general 34,95 (coste 15,00); */27 35,95 (coste 15,50)».
function ResumenFilasPrecioTarifa(
  const AArticulo: TArticuloPreciosTarifa): string;
// Mensaje del primer precio no válido; vacío si todos lo son.
function ValidarPreciosCeldasSesion(
  const APrecios: TPreciosCeldasSesion): string;

implementation

uses
  System.SysUtils,
  inLibMsgCompras;

const
  TOLERANCIA_PRECIO = 0.00005;
  COMODIN_TALLA = '/*/';
  PRIORIDAD_SKU = 0;
  PRIORIDAD_TALLA = 1;
  PRIORIDAD_COLOR = 2;
  PRIORIDAD_GENERAL = 3;
  SIN_PRIORIDAD = 4;

type
  TMedidaPrecio = (mpCoste, mpPvp);
  // La medida de la fila la fija el patrón (no se completa después).
  TMarcasMedida = array[TMedidaPrecio] of Boolean;

function MismoPrecio(AUno, AOtro: Double): Boolean;
begin
  Result := Abs(AUno - AOtro) < TOLERANCIA_PRECIO;
end;

function ValorMedida(const ASku: TPrecioSkuSesion;
  AMedida: TMedidaPrecio): Double;
begin
  if AMedida = mpCoste then
    Result := ASku.Coste
  else
    Result := ASku.Pvp;
end;

function ValorFila(const AFila: TFilaPrecioTarifa;
  AMedida: TMedidaPrecio): Double;
begin
  if AMedida = mpCoste then
    Result := AFila.Coste
  else
    Result := AFila.Pvp;
end;

procedure PonerValorFila(var AFila: TFilaPrecioTarifa;
  AMedida: TMedidaPrecio; AValor: Double);
begin
  if AMedida = mpCoste then
    AFila.Coste := AValor
  else
    AFila.Pvp := AValor;
end;

function ClaveTallaTarifa(const ACodigoArticulo, ATalla: string): string;
begin
  Result := Trim(ACodigoArticulo) + COMODIN_TALLA + Trim(ATalla);
end;

function PrioridadFila(const ACodigoArticulo, AClave: string;
  const ASku: TPrecioSkuSesion): Integer;
var
  sClave: string;
begin
  sClave := Trim(AClave);
  if sClave = '' then
    Result := PRIORIDAD_GENERAL
  else if SameText(sClave, ASku.CodigoSku) then
    Result := PRIORIDAD_SKU
  else if Pos(COMODIN_TALLA, sClave) > 0 then
  begin
    if (ASku.Talla <> '') and
       SameText(sClave, ClaveTallaTarifa(ACodigoArticulo, ASku.Talla)) then
      Result := PRIORIDAD_TALLA
    else
      Result := SIN_PRIORIDAD;
  end
  else if SameText(sClave + '/',
         Copy(ASku.CodigoSku, 1, Length(sClave) + 1)) then
    Result := PRIORIDAD_COLOR
  else
    Result := SIN_PRIORIDAD;
end;

function ResolverFilaPrecioTarifa(const ACodigoArticulo: string;
  const AFilas: TFilasPrecioTarifa; const ASku: TPrecioSkuSesion): Integer;
var
  iFila: Integer;
  iPrioridad: Integer;
  iMejor: Integer;
begin
  Result := -1;
  iMejor := SIN_PRIORIDAD;
  for iFila := 0 to High(AFilas) do
  begin
    iPrioridad := PrioridadFila(ACodigoArticulo, AFilas[iFila].Clave, ASku);
    // Entre dos prefijos de color gana el más largo, como en el SQL.
    if (iPrioridad < iMejor) or
       ((iPrioridad = iMejor) and (iPrioridad = PRIORIDAD_COLOR) and
        (Length(AFilas[iFila].Clave) > Length(AFilas[Result].Clave))) then
    begin
      iMejor := iPrioridad;
      Result := iFila;
    end;
  end;
end;

function IndiceClave(const AFilas: TFilasPrecioTarifa;
  const AClave: string): Integer;
var
  iFila: Integer;
begin
  Result := -1;
  iFila := 0;
  while (Result = -1) and (iFila <= High(AFilas)) do
  begin
    if SameText(Trim(AFilas[iFila].Clave), Trim(AClave)) then
      Result := iFila;
    Inc(iFila);
  end;
end;

procedure AnadirTexto(var ALista: TArray<string>; const ATexto: string);
var
  iTexto: Integer;
  bEsta: Boolean;
begin
  bEsta := False;
  for iTexto := 0 to High(ALista) do
    bEsta := bEsta or SameText(ALista[iTexto], ATexto);
  if not bEsta then
  begin
    SetLength(ALista, Length(ALista) + 1);
    ALista[High(ALista)] := ATexto;
  end;
end;

// Precio más repetido. En empate, el de la línea si está entre los
// empatados; si no, el que aparece antes.
function PrecioMasRepetido(const AValores: TArray<Double>;
  AReferencia: Double): Double;
var
  iValor: Integer;
  iVeces: Integer;
  iMaximo: Integer;
  bReferenciaMaxima: Boolean;

  function Veces(AValor: Double): Integer;
  var
    iBusqueda: Integer;
  begin
    Result := 0;
    for iBusqueda := 0 to High(AValores) do
      if MismoPrecio(AValores[iBusqueda], AValor) then
        Inc(Result);
  end;

begin
  Result := AReferencia;
  iMaximo := 0;
  for iValor := 0 to High(AValores) do
  begin
    iVeces := Veces(AValores[iValor]);
    if iVeces > iMaximo then
    begin
      iMaximo := iVeces;
      Result := AValores[iValor];
    end;
  end;
  bReferenciaMaxima := (iMaximo > 0) and (Veces(AReferencia) = iMaximo);
  if bReferenciaMaxima then
    Result := AReferencia;
end;

function ValoresDe(const APrecios: TPreciosSkuSesion;
  AMedida: TMedidaPrecio): TArray<Double>;
var
  iSku: Integer;
begin
  SetLength(Result, Length(APrecios));
  for iSku := 0 to High(APrecios) do
    Result[iSku] := ValorMedida(APrecios[iSku], AMedida);
end;

// Todos los SKU del grupo (talla o color) tienen el mismo valor.
function GrupoUniforme(const APrecios: TPreciosSkuSesion;
  AMedida: TMedidaPrecio; const AClave: string; APorTalla: Boolean;
  out AValor: Double): Boolean;
var
  iSku: Integer;
  bHay: Boolean;
  sGrupo: string;
begin
  Result := True;
  bHay := False;
  AValor := 0;
  for iSku := 0 to High(APrecios) do
  begin
    if APorTalla then
      sGrupo := APrecios[iSku].Talla
    else
      sGrupo := APrecios[iSku].ClaveColor;
    if SameText(sGrupo, AClave) then
    begin
      if not bHay then
        AValor := ValorMedida(APrecios[iSku], AMedida)
      else if not MismoPrecio(AValor,
                ValorMedida(APrecios[iSku], AMedida)) then
        Result := False;
      bHay := True;
    end;
  end;
  Result := Result and bHay;
end;

function TamanoGrupo(const APrecios: TPreciosSkuSesion;
  const AClave: string; APorTalla: Boolean): Integer;
var
  oPrecio: TPrecioSkuSesion;
begin
  Result := 0;
  for oPrecio in APrecios do
    if (APorTalla and SameText(oPrecio.Talla, AClave)) or
       ((not APorTalla) and SameText(oPrecio.ClaveColor, AClave)) then
      Inc(Result);
end;

procedure PonerCandidata(var AFilas: TFilasPrecioTarifa;
  var AMarcas: TArray<TMarcasMedida>; const AClave: string;
  AMedida: TMedidaPrecio; AValor: Double);
var
  iFila: Integer;
begin
  iFila := IndiceClave(AFilas, AClave);
  if iFila = -1 then
  begin
    iFila := Length(AFilas);
    SetLength(AFilas, iFila + 1);
    SetLength(AMarcas, iFila + 1);
    AFilas[iFila].Clave := AClave;
    AMarcas[iFila][mpCoste] := False;
    AMarcas[iFila][mpPvp] := False;
  end;
  PonerValorFila(AFilas[iFila], AMedida, AValor);
  AMarcas[iFila][AMedida] := True;
end;

// Combina las filas nuevas con las vigentes que no sustituyen.
function FilasEfectivas(const ANuevas,
  AVigentes: TFilasPrecioTarifa): TFilasPrecioTarifa;
var
  iFila: Integer;
begin
  Result := Copy(ANuevas);
  for iFila := 0 to High(AVigentes) do
    if IndiceClave(ANuevas, AVigentes[iFila].Clave) = -1 then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := AVigentes[iFila];
    end;
end;

procedure CandidatasMedida(const ACodigoArticulo: string;
  const APrecios: TPreciosSkuSesion; AMedida: TMedidaPrecio;
  const ATallas, AColores: TArray<string>;
  var AFilas: TFilasPrecioTarifa; var AMarcas: TArray<TMarcasMedida>);
var
  dGeneral: Double;
  dValor: Double;
  iGrupo: Integer;
  iSku: Integer;
  bExplicado: Boolean;
  oFilasMedida: TFilasPrecioTarifa;
begin
  dGeneral := ValorFila(AFilas[0], AMedida);
  // Una fila de talla o de color solo se crea si explica el precio de al
  // menos dos SKU distinto del general; si no, basta la fila del SKU.
  // a) Talla con el mismo precio en todos sus colores.
  SetLength(oFilasMedida, 1);
  oFilasMedida[0] := AFilas[0];
  for iGrupo := 0 to High(ATallas) do
    if GrupoUniforme(APrecios, AMedida, ATallas[iGrupo], True, dValor) and
       (TamanoGrupo(APrecios, ATallas[iGrupo], True) > 1) and
       not MismoPrecio(dValor, dGeneral) then
    begin
      PonerCandidata(AFilas, AMarcas,
        ClaveTallaTarifa(ACodigoArticulo, ATallas[iGrupo]), AMedida, dValor);
      SetLength(oFilasMedida, Length(oFilasMedida) + 1);
      oFilasMedida[High(oFilasMedida)].Clave :=
        ClaveTallaTarifa(ACodigoArticulo, ATallas[iGrupo]);
      PonerValorFila(oFilasMedida[High(oFilasMedida)], AMedida, dValor);
    end;
  // b) Color con el mismo precio en todas sus tallas, distinto del
  // general, si las filas de talla no lo explican ya.
  for iGrupo := 0 to High(AColores) do
    if (AColores[iGrupo] <> '') and
       GrupoUniforme(APrecios, AMedida, AColores[iGrupo], False, dValor) and
       (TamanoGrupo(APrecios, AColores[iGrupo], False) > 1) and
       not MismoPrecio(dValor, dGeneral) then
    begin
      bExplicado := True;
      for iSku := 0 to High(APrecios) do
        if SameText(APrecios[iSku].ClaveColor, AColores[iGrupo]) then
          bExplicado := bExplicado and
            (ResolverFilaPrecioTarifa(ACodigoArticulo, oFilasMedida,
               APrecios[iSku]) > 0);
      if not bExplicado then
        PonerCandidata(AFilas, AMarcas, AColores[iGrupo], AMedida, dValor);
    end;
end;

// Valor de una medida en las filas que solo pide la otra: el más repetido
// entre los SKU que resuelven a ella; sin ninguno, el general.
procedure CompletarFilas(const ACodigoArticulo: string;
  const APrecios: TPreciosSkuSesion; const AVigentes: TFilasPrecioTarifa;
  var AFilas: TFilasPrecioTarifa; const AMarcas: TArray<TMarcasMedida>);
var
  oEfectivas: TFilasPrecioTarifa;
  oValores: TArray<Double>;
  eMedida: TMedidaPrecio;
  iFila: Integer;
  iSku: Integer;
begin
  oEfectivas := FilasEfectivas(AFilas, AVigentes);
  for iFila := 1 to High(AFilas) do
    for eMedida := Low(TMedidaPrecio) to High(TMedidaPrecio) do
      if not AMarcas[iFila][eMedida] then
      begin
        SetLength(oValores, 0);
        for iSku := 0 to High(APrecios) do
          if ResolverFilaPrecioTarifa(ACodigoArticulo, oEfectivas,
               APrecios[iSku]) = iFila then
          begin
            SetLength(oValores, Length(oValores) + 1);
            oValores[High(oValores)] := ValorMedida(APrecios[iSku], eMedida);
          end;
        PonerValorFila(AFilas[iFila], eMedida, PrecioMasRepetido(oValores,
          ValorFila(AFilas[0], eMedida)));
      end;
end;

function SkuBienResuelto(const ACodigoArticulo: string;
  const AFilas: TFilasPrecioTarifa; const ASku: TPrecioSkuSesion): Boolean;
var
  iFila: Integer;
begin
  iFila := ResolverFilaPrecioTarifa(ACodigoArticulo, AFilas, ASku);
  Result := (iFila >= 0) and MismoPrecio(AFilas[iFila].Coste, ASku.Coste) and
    MismoPrecio(AFilas[iFila].Pvp, ASku.Pvp);
end;

// d) Comprobación final: el SKU cuyo precio no queda explicado recibe su
// fila exacta. Se repite porque un SKU sin talla puede ser prefijo de otro.
procedure AnadirFilasSku(const ACodigoArticulo: string;
  const APrecios: TPreciosSkuSesion; const AVigentes: TFilasPrecioTarifa;
  var AFilas: TFilasPrecioTarifa);
var
  iSku: Integer;
  iVuelta: Integer;
  iFila: Integer;
  bCambia: Boolean;
begin
  iVuelta := 0;
  repeat
    bCambia := False;
    for iSku := 0 to High(APrecios) do
      if not SkuBienResuelto(ACodigoArticulo,
               FilasEfectivas(AFilas, AVigentes), APrecios[iSku]) then
      begin
        iFila := IndiceClave(AFilas, APrecios[iSku].CodigoSku);
        if iFila = -1 then
        begin
          iFila := Length(AFilas);
          SetLength(AFilas, iFila + 1);
        end;
        AFilas[iFila].Clave := APrecios[iSku].CodigoSku;
        AFilas[iFila].Coste := APrecios[iSku].Coste;
        AFilas[iFila].Pvp := APrecios[iSku].Pvp;
        bCambia := True;
      end;
    Inc(iVuelta);
  until (not bCambia) or (iVuelta > Length(APrecios));
end;

function CalcularFilasPrecioTarifa(const ACodigoArticulo: string;
  const APrecios: TPreciosSkuSesion;
  const AReferencia: TFilaPrecioTarifa;
  const AVigentes: TFilasPrecioTarifa): TFilasPrecioTarifa;
var
  oMarcas: TArray<TMarcasMedida>;
  oTallas: TArray<string>;
  oColores: TArray<string>;
  eMedida: TMedidaPrecio;
  iSku: Integer;
begin
  SetLength(Result, 1);
  SetLength(oMarcas, 1);
  Result[0].Clave := '';
  // c) La fila general lleva el precio más repetido de cada medida.
  Result[0].Coste := PrecioMasRepetido(ValoresDe(APrecios, mpCoste),
    AReferencia.Coste);
  Result[0].Pvp := PrecioMasRepetido(ValoresDe(APrecios, mpPvp),
    AReferencia.Pvp);
  oMarcas[0][mpCoste] := True;
  oMarcas[0][mpPvp] := True;
  SetLength(oTallas, 0);
  SetLength(oColores, 0);
  for iSku := 0 to High(APrecios) do
  begin
    if APrecios[iSku].Talla <> '' then
      AnadirTexto(oTallas, APrecios[iSku].Talla);
    AnadirTexto(oColores, APrecios[iSku].ClaveColor);
  end;
  for eMedida := Low(TMedidaPrecio) to High(TMedidaPrecio) do
    CandidatasMedida(ACodigoArticulo, APrecios, eMedida, oTallas, oColores,
      Result, oMarcas);
  CompletarFilas(ACodigoArticulo, APrecios, AVigentes, Result, oMarcas);
  AnadirFilasSku(ACodigoArticulo, APrecios, AVigentes, Result);
end;

function TienePreciosPorTalla(const AFilas: TFilasPrecioTarifa): Boolean;
begin
  Result := Length(AFilas) > 1;
end;

function EtiquetaFila(const ACodigoArticulo, AClave: string): string;
var
  sPrefijo: string;
begin
  sPrefijo := Trim(ACodigoArticulo) + '/';
  if Trim(AClave) = '' then
    Result := SEtiquetaFilaGeneralPreciosTalla
  else if SameText(Copy(AClave, 1, Length(sPrefijo)), sPrefijo) then
    Result := Copy(AClave, Length(sPrefijo) + 1, MaxInt)
  else
    Result := AClave;
end;

function ResumenFilasPrecioTarifa(
  const AArticulo: TArticuloPreciosTarifa): string;
var
  iFila: Integer;
begin
  Result := '';
  for iFila := 0 to High(AArticulo.Filas) do
  begin
    if Result <> '' then
      Result := Result + '; ';
    Result := Result + Format(SFilaResumenPreciosTalla,
      [EtiquetaFila(AArticulo.CodigoArticulo, AArticulo.Filas[iFila].Clave),
       FormatFloat('#,##0.00##', AArticulo.Filas[iFila].Pvp),
       FormatFloat('#,##0.00##', AArticulo.Filas[iFila].Coste)]);
  end;
  Result := AArticulo.CodigoArticulo + ': ' + Result;
end;

function ValidarPreciosCeldasSesion(
  const APrecios: TPreciosCeldasSesion): string;
var
  iCelda: Integer;
begin
  Result := '';
  iCelda := 0;
  while (Result = '') and (iCelda <= High(APrecios)) do
  begin
    if (APrecios[iCelda].TieneCoste and (APrecios[iCelda].Coste < 0)) or
       (APrecios[iCelda].TienePvp and (APrecios[iCelda].Pvp < 0)) then
      Result := Format(SErrorPreciosTallaNegativo,
        [APrecios[iCelda].Color, APrecios[iCelda].Talla]);
    Inc(iCelda);
  end;
end;

end.
