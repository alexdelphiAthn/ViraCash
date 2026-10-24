{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGs1                                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Lectura y composición de códigos GS1-128 / GS1 DataMatrix (F-LOTEC):      }
{    GTIN (IA 01 y 02), lote (10), caducidad (17), serie (21) y cantidad      }
{    (37). Admite el separador FNC1 (GS), el prefijo de simbología (]C1,       }
{    ]d2, ]Q3, ]e0, ]J1) y la forma legible con paréntesis.                    }
{******************************************************************************}
unit inLibGs1;

interface

const
  // FNC1 tal como lo transmite el lector: carácter GS.
  GS1_SEPARADOR = #29;

  IA_GTIN = '01';
  IA_GTIN_CONTENIDO = '02';
  IA_LOTE = '10';
  IA_CADUCIDAD = '17';
  IA_SERIE = '21';
  IA_CANTIDAD = '37';

  LONGITUD_GTIN = 14;
  LONGITUD_MAXIMA_LOTE_GS1 = 20;
  LONGITUD_MAXIMA_SERIE_GS1 = 20;
  LONGITUD_MAXIMA_CANTIDAD_GS1 = 8;

type
  TFormatoGs1 = (
    fgsMaquina,
    fgsLegible
  );

  TErrorGs1 = (
    egsSinError,
    egsNoEsGs1,
    egsIdentificadorDesconocido,
    egsIdentificadorRepetido,
    egsLongitudIncorrecta,
    egsCaracterNoPermitido,
    egsGtinInvalido,
    egsFechaInvalida,
    egsCantidadInvalida
  );

  // Lo que interesa a ViraCash de un código GS1. Los demás identificadores
  // de aplicación se validan y se ignoran.
  TDatosGs1 = record
    Gtin: string;
    GtinContenido: string;
    Lote: string;
    Serie: string;
    FechaCaducidad: TDate;
    Cantidad: Integer;
  end;

  TResultadoGs1 = record
    Error: TErrorGs1;
    // Identificador de aplicación en el que falló (vacío si no aplica).
    Identificador: string;
    Datos: TDatosGs1;
    function EsValido: Boolean;
  end;

// True si la lectura parece GS1 (prefijo de simbología, separador GS,
// forma con paréntesis o «01»/«02» + GTIN-14 válido seguido de más datos).
function EsLecturaGs1(const ALectura: string): Boolean;
function InterpretarGs1(
  const ALectura: string;
  AFechaReferencia: TDate): TResultadoGs1; overload;
function InterpretarGs1(const ALectura: string): TResultadoGs1; overload;
function ComponerGs1(
  const ADatos: TDatosGs1;
  AFormato: TFormatoGs1;
  out ACodigo: string): TErrorGs1;

function EsGtinValido(const AGtin: string): Boolean;
// GTIN-8/12/13/14 a 14 dígitos (ceros a la izquierda). Vacío si no vale.
function GtinA14(const AGtin: string): string;
// GTIN-14 al código que se guarda en fza_codigos_barras: EAN-13 si empieza
// por 0, EAN-8 si empieza por 000000; si no, los 14 dígitos.
function GtinACodigoComercial(const AGtin: string): string;
// AAMMDD con la regla de siglo de GS1; DD = 00 es el último día del mes.
function FechaGs1(
  const AAAMMDD: string;
  AFechaReferencia: TDate;
  out AFecha: TDate): Boolean;
function EsTextoGs1Valido(const ATexto: string): Boolean;

implementation

uses
  System.SysUtils, System.DateUtils;

const
  PREFIJOS_SIMBOLOGIA_GS1: array[0..4] of string = (
    ']C1', ']d2', ']Q3', ']e0', ']J1');
  LONGITUD_PREFIJO_SIMBOLOGIA = 3;
  // Conjunto de caracteres 82 de GS1 (texto de lote y serie).
  CARACTERES_GS1_EXTRA = '!"%&''()*+,-./:;<=>?_';
  BLANCOS: TSysCharSet = [' ', #9, #10, #13];

function TResultadoGs1.EsValido: Boolean;
begin
  Result := Error = egsSinError;
end;

function SoloDigitos(const ATexto: string): Boolean;
var
  cCaracter: Char;
begin
  Result := ATexto <> '';
  for cCaracter in ATexto do
  begin
    if not CharInSet(cCaracter, ['0'..'9']) then
      Result := False;
  end;
end;

function EsTextoGs1Valido(const ATexto: string): Boolean;
var
  cCaracter: Char;
begin
  Result := ATexto <> '';
  for cCaracter in ATexto do
  begin
    if not (CharInSet(cCaracter, ['0'..'9', 'A'..'Z', 'a'..'z']) or
            (Pos(cCaracter, CARACTERES_GS1_EXTRA) > 0)) then
      Result := False;
  end;
end;

function EsGtinValido(const AGtin: string): Boolean;
var
  iIndice: Integer;
  iPeso: Integer;
  iSuma: Integer;
begin
  // Módulo 10 con pesos 3 y 1 desde la derecha, sin el dígito de control
  // (vale para GTIN-8, 12, 13 y 14).
  Result := SoloDigitos(AGtin) and
            ((Length(AGtin) = 8) or (Length(AGtin) = 12) or
             (Length(AGtin) = 13) or (Length(AGtin) = LONGITUD_GTIN));
  if Result then
  begin
    iSuma := 0;
    iPeso := 3;
    for iIndice := Length(AGtin) - 1 downto 1 do
    begin
      iSuma := iSuma + (Ord(AGtin[iIndice]) - Ord('0')) * iPeso;
      iPeso := 4 - iPeso;
    end;
    Result := (10 - (iSuma mod 10)) mod 10 =
              Ord(AGtin[Length(AGtin)]) - Ord('0');
  end;
end;

function GtinA14(const AGtin: string): string;
begin
  if EsGtinValido(AGtin) then
    Result := StringOfChar('0', LONGITUD_GTIN - Length(AGtin)) + AGtin
  else
    Result := '';
end;

function GtinACodigoComercial(const AGtin: string): string;
begin
  if Copy(AGtin, 1, 6) = '000000' then
    Result := Copy(AGtin, 7, 8)
  else if Copy(AGtin, 1, 1) = '0' then
    Result := Copy(AGtin, 2, 13)
  else
    Result := AGtin;
end;

function FechaGs1(
  const AAAMMDD: string;
  AFechaReferencia: TDate;
  out AFecha: TDate): Boolean;
var
  dtFecha: TDateTime;
  iAnio: Integer;
  iAnioReferencia: Integer;
  iDia: Integer;
  iDiferencia: Integer;
  iMes: Integer;
begin
  AFecha := 0;
  Result := (Length(AAAMMDD) = 6) and SoloDigitos(AAAMMDD);
  if Result then
  begin
    iAnio := StrToInt(Copy(AAAMMDD, 1, 2));
    iMes := StrToInt(Copy(AAAMMDD, 3, 2));
    iDia := StrToInt(Copy(AAAMMDD, 5, 2));
    // Regla de siglo de las especificaciones GS1 (7.12): hasta 49 años
    // hacia delante y 50 hacia atrás respecto de la fecha de referencia.
    iAnioReferencia := YearOf(AFechaReferencia);
    iDiferencia := iAnio - (iAnioReferencia mod 100);
    iAnio := iAnioReferencia - (iAnioReferencia mod 100) + iAnio;
    if iDiferencia >= 51 then
      iAnio := iAnio - 100
    else if iDiferencia <= -50 then
      iAnio := iAnio + 100;
    Result := (iMes >= 1) and (iMes <= 12);
    if Result and (iDia = 0) then
      iDia := DaysInAMonth(iAnio, iMes);
    Result := Result and TryEncodeDate(iAnio, iMes, iDia, dtFecha);
    if Result then
      AFecha := dtFecha;
  end;
end;

function LongitudIdentificador(const AInicio: string): Integer;
var
  iPrefijo: Integer;
begin
  // Longitud del identificador según sus dos primeras cifras (tabla de las
  // especificaciones generales GS1). 0 = prefijo sin asignar.
  iPrefijo := StrToIntDef(AInicio, -1);
  case iPrefijo of
    0..22, 30, 37, 90..99:
      Result := 2;
    23..25, 40..42:
      Result := 3;
    31..36, 39, 43, 70..72, 80..82:
      Result := 4;
  else
    Result := 0;
  end;
end;

function LongitudFijaDatos(const AIdentificador: string): Integer;
var
  iPrefijo: Integer;
begin
  // Identificadores de longitud predefinida: no llevan separador detrás.
  // 0 = longitud variable (termina en GS o al final).
  iPrefijo := StrToIntDef(Copy(AIdentificador, 1, 2), -1);
  case iPrefijo of
    0:
      Result := 18;
    1..3:
      Result := LONGITUD_GTIN;
    4:
      Result := 16;
    11..19:
      Result := 6;
    20:
      Result := 2;
    31..36:
      Result := 6;
    41:
      Result := 13;
  else
    Result := 0;
  end;
end;

function QuitarBlancos(const ATexto: string): string;
var
  iFin: Integer;
  iInicio: Integer;
begin
  // No vale Trim: quitaría también el GS inicial o final, que aquí se
  // trata aparte.
  iInicio := 1;
  iFin := Length(ATexto);
  while (iInicio <= iFin) and CharInSet(ATexto[iInicio], BLANCOS) do
    Inc(iInicio);
  while (iFin >= iInicio) and CharInSet(ATexto[iFin], BLANCOS) do
    Dec(iFin);
  Result := Copy(ATexto, iInicio, iFin - iInicio + 1);
end;

function TienePrefijoSimbologiaGs1(const ALectura: string): Boolean;
var
  sPrefijo: string;
begin
  Result := False;
  for sPrefijo in PREFIJOS_SIMBOLOGIA_GS1 do
  begin
    if Copy(ALectura, 1, LONGITUD_PREFIJO_SIMBOLOGIA) = sPrefijo then
      Result := True;
  end;
end;

function EmpiezaPorGtinGs1(const ALectura: string): Boolean;
begin
  // Sin prefijo ni separador solo se reconoce lo que empieza por un GTIN
  // con IA y dígito de control correctos: un EAN-13 suelto no es GS1.
  Result := (Length(ALectura) > 2 + LONGITUD_GTIN) and
            ((Copy(ALectura, 1, 2) = IA_GTIN) or
             (Copy(ALectura, 1, 2) = IA_GTIN_CONTENIDO)) and
            EsGtinValido(Copy(ALectura, 3, LONGITUD_GTIN));
end;

function EsLecturaGs1(const ALectura: string): Boolean;
var
  sLectura: string;
begin
  sLectura := QuitarBlancos(ALectura);
  Result := TienePrefijoSimbologiaGs1(sLectura) or
            (Pos(GS1_SEPARADOR, sLectura) > 0) or
            (Copy(sLectura, 1, 1) = '(') or
            EmpiezaPorGtinGs1(sLectura);
end;

type
  TElementoGs1 = record
    Identificador: string;
    Valor: string;
  end;
  TElementosGs1 = TArray<TElementoGs1>;

function Elemento(const AIdentificador, AValor: string): TElementoGs1;
begin
  Result.Identificador := AIdentificador;
  Result.Valor := AValor;
end;

function TrocearMaquina(
  const ATexto: string;
  out AElementos: TElementosGs1;
  out AIdentificador: string): TErrorGs1;
var
  iFin: Integer;
  iLongitud: Integer;
  iPosicion: Integer;
begin
  AElementos := [];
  AIdentificador := '';
  Result := egsSinError;
  iPosicion := 1;
  while (Result = egsSinError) and (iPosicion <= Length(ATexto)) do
  begin
    if ATexto[iPosicion] = GS1_SEPARADOR then
      Inc(iPosicion)
    else
    begin
      iLongitud := LongitudIdentificador(Copy(ATexto, iPosicion, 2));
      AIdentificador := Copy(ATexto, iPosicion, iLongitud);
      if (iLongitud = 0) or (Length(AIdentificador) < iLongitud) or
         not SoloDigitos(AIdentificador) then
      begin
        AIdentificador := Copy(ATexto, iPosicion, 2);
        Result := egsIdentificadorDesconocido;
      end
      else
      begin
        iPosicion := iPosicion + iLongitud;
        iLongitud := LongitudFijaDatos(AIdentificador);
        if iLongitud > 0 then
          iFin := iPosicion + iLongitud
        else
        begin
          iFin := iPosicion;
          while (iFin <= Length(ATexto)) and
                (ATexto[iFin] <> GS1_SEPARADOR) do
            Inc(iFin);
        end;
        if (iFin = iPosicion) or (iFin > Length(ATexto) + 1) then
          Result := egsLongitudIncorrecta
        else
        begin
          AElementos := AElementos + [Elemento(AIdentificador,
                          Copy(ATexto, iPosicion, iFin - iPosicion))];
          iPosicion := iFin;
        end;
      end;
    end;
  end;
end;

function TrocearLegible(
  const ATexto: string;
  out AElementos: TElementosGs1;
  out AIdentificador: string): TErrorGs1;
var
  iCierre: Integer;
  iPosicion: Integer;
  iSiguiente: Integer;
begin
  // (01)08412345678905(17)261231(10)L-23: cada valor llega hasta el
  // siguiente «(» o el final.
  AElementos := [];
  AIdentificador := '';
  Result := egsSinError;
  iPosicion := 1;
  while (Result = egsSinError) and (iPosicion <= Length(ATexto)) do
  begin
    iCierre := Pos(')', ATexto, iPosicion);
    if (ATexto[iPosicion] <> '(') or (iCierre = 0) then
      Result := egsIdentificadorDesconocido
    else
    begin
      AIdentificador := Copy(ATexto, iPosicion + 1, iCierre - iPosicion - 1);
      iSiguiente := Pos('(', ATexto, iCierre);
      if iSiguiente = 0 then
        iSiguiente := Length(ATexto) + 1;
      if (LongitudIdentificador(Copy(AIdentificador, 1, 2)) <>
          Length(AIdentificador)) or not SoloDigitos(AIdentificador) then
        Result := egsIdentificadorDesconocido
      else if (LongitudFijaDatos(AIdentificador) > 0) and
              (iSiguiente - iCierre - 1 <>
               LongitudFijaDatos(AIdentificador)) then
        Result := egsLongitudIncorrecta
      else if iSiguiente = iCierre + 1 then
        Result := egsLongitudIncorrecta
      else
      begin
        AElementos := AElementos + [Elemento(AIdentificador,
                        Copy(ATexto, iCierre + 1, iSiguiente - iCierre - 1))];
        iPosicion := iSiguiente;
      end;
    end;
  end;
end;

function AplicarElemento(
  const AElemento: TElementoGs1;
  AFechaReferencia: TDate;
  var ADatos: TDatosGs1): TErrorGs1;
var
  dtFecha: TDate;
  iCantidad: Integer;
begin
  Result := egsSinError;
  if (AElemento.Identificador = IA_GTIN) or
     (AElemento.Identificador = IA_GTIN_CONTENIDO) then
  begin
    if not EsGtinValido(AElemento.Valor) or
       (Length(AElemento.Valor) <> LONGITUD_GTIN) then
      Result := egsGtinInvalido
    else if AElemento.Identificador = IA_GTIN then
      ADatos.Gtin := AElemento.Valor
    else
      ADatos.GtinContenido := AElemento.Valor;
  end
  else if AElemento.Identificador = IA_CADUCIDAD then
  begin
    if FechaGs1(AElemento.Valor, AFechaReferencia, dtFecha) then
      ADatos.FechaCaducidad := dtFecha
    else
      Result := egsFechaInvalida;
  end
  else if (AElemento.Identificador = IA_LOTE) or
          (AElemento.Identificador = IA_SERIE) then
  begin
    if Length(AElemento.Valor) > LONGITUD_MAXIMA_LOTE_GS1 then
      Result := egsLongitudIncorrecta
    else if not EsTextoGs1Valido(AElemento.Valor) then
      Result := egsCaracterNoPermitido
    else if AElemento.Identificador = IA_LOTE then
      ADatos.Lote := AElemento.Valor
    else
      ADatos.Serie := AElemento.Valor;
  end
  else if AElemento.Identificador = IA_CANTIDAD then
  begin
    iCantidad := 0;
    if (Length(AElemento.Valor) > LONGITUD_MAXIMA_CANTIDAD_GS1) or
       not SoloDigitos(AElemento.Valor) or
       not TryStrToInt(AElemento.Valor, iCantidad) or (iCantidad <= 0) then
      Result := egsCantidadInvalida
    else
      ADatos.Cantidad := iCantidad;
  end;
end;

function IdentificadorRepetido(
  const AElementos: TElementosGs1;
  out AIdentificador: string): Boolean;
var
  iIndice: Integer;
  iOtro: Integer;
begin
  Result := False;
  AIdentificador := '';
  for iIndice := 0 to High(AElementos) do
  begin
    for iOtro := iIndice + 1 to High(AElementos) do
    begin
      if AElementos[iIndice].Identificador =
         AElementos[iOtro].Identificador then
      begin
        Result := True;
        AIdentificador := AElementos[iIndice].Identificador;
      end;
    end;
  end;
end;

function QuitarPrefijoSimbologia(
  const ALectura: string;
  out AEsGs1: Boolean): string;
begin
  // ]C1, ]d2... confirman GS1; otro identificador de simbología (]E0 de
  // un EAN-13, ]C0 de un Code128 normal) lo descarta.
  AEsGs1 := TienePrefijoSimbologiaGs1(ALectura);
  if Copy(ALectura, 1, 1) = ']' then
    Result := Copy(ALectura, LONGITUD_PREFIJO_SIMBOLOGIA + 1, MaxInt)
  else
    Result := ALectura;
end;

function InterpretarGs1(
  const ALectura: string;
  AFechaReferencia: TDate): TResultadoGs1;
var
  aElementos: TElementosGs1;
  EsGs1: Boolean;
  iIndice: Integer;
  sIdentificador: string;
  sTexto: string;
begin
  Result := Default(TResultadoGs1);
  sTexto := QuitarBlancos(ALectura);
  if Copy(sTexto, 1, 1) = ']' then
    sTexto := QuitarPrefijoSimbologia(sTexto, EsGs1)
  else
    EsGs1 := EsLecturaGs1(sTexto);
  if not EsGs1 then
    Result.Error := egsNoEsGs1
  else
  begin
    if Copy(sTexto, 1, 1) = '(' then
      Result.Error := TrocearLegible(sTexto, aElementos, sIdentificador)
    else
      Result.Error := TrocearMaquina(sTexto, aElementos, sIdentificador);
    if (Result.Error = egsSinError) and (Length(aElementos) = 0) then
      Result.Error := egsLongitudIncorrecta;
    if (Result.Error = egsSinError) and
       IdentificadorRepetido(aElementos, sIdentificador) then
      Result.Error := egsIdentificadorRepetido;
    iIndice := 0;
    while (Result.Error = egsSinError) and (iIndice <= High(aElementos)) do
    begin
      sIdentificador := aElementos[iIndice].Identificador;
      Result.Error := AplicarElemento(aElementos[iIndice], AFechaReferencia,
                                      Result.Datos);
      Inc(iIndice);
    end;
    if Result.Error <> egsSinError then
    begin
      Result.Identificador := sIdentificador;
      Result.Datos := Default(TDatosGs1);
    end;
  end;
end;

function InterpretarGs1(const ALectura: string): TResultadoGs1;
begin
  Result := InterpretarGs1(ALectura, Date);
end;

function ComponerGs1(
  const ADatos: TDatosGs1;
  AFormato: TFormatoGs1;
  out ACodigo: string): TErrorGs1;
var
  aElementos: TElementosGs1;
  iIndice: Integer;
  sGtin: string;
begin
  // Primero los de longitud fija y al final los variables: así solo hace
  // falta GS entre variables, nunca tras el último.
  ACodigo := '';
  Result := egsSinError;
  aElementos := [];
  if ADatos.Gtin <> '' then
  begin
    sGtin := GtinA14(ADatos.Gtin);
    if sGtin = '' then
      Result := egsGtinInvalido;
    aElementos := aElementos + [Elemento(IA_GTIN, sGtin)];
  end;
  if ADatos.GtinContenido <> '' then
  begin
    sGtin := GtinA14(ADatos.GtinContenido);
    if sGtin = '' then
      Result := egsGtinInvalido;
    aElementos := aElementos + [Elemento(IA_GTIN_CONTENIDO, sGtin)];
  end;
  if ADatos.FechaCaducidad <> 0 then
    aElementos := aElementos + [Elemento(IA_CADUCIDAD,
                    FormatDateTime('yymmdd', ADatos.FechaCaducidad))];
  if ADatos.Cantidad > 0 then
    aElementos := aElementos + [Elemento(IA_CANTIDAD,
                    IntToStr(ADatos.Cantidad))];
  if ADatos.Lote <> '' then
    aElementos := aElementos + [Elemento(IA_LOTE, ADatos.Lote)];
  if ADatos.Serie <> '' then
    aElementos := aElementos + [Elemento(IA_SERIE, ADatos.Serie)];
  if (Result = egsSinError) and (Length(aElementos) = 0) then
    Result := egsLongitudIncorrecta;
  for iIndice := 0 to High(aElementos) do
  begin
    if (Result = egsSinError) and
       ((aElementos[iIndice].Identificador = IA_LOTE) or
        (aElementos[iIndice].Identificador = IA_SERIE)) then
    begin
      if Length(aElementos[iIndice].Valor) > LONGITUD_MAXIMA_LOTE_GS1 then
        Result := egsLongitudIncorrecta
      else if not EsTextoGs1Valido(aElementos[iIndice].Valor) then
        Result := egsCaracterNoPermitido;
    end;
  end;
  if Result = egsSinError then
  begin
    for iIndice := 0 to High(aElementos) do
    begin
      if AFormato = fgsLegible then
        ACodigo := ACodigo + '(' + aElementos[iIndice].Identificador + ')' +
                   aElementos[iIndice].Valor
      else
      begin
        ACodigo := ACodigo + aElementos[iIndice].Identificador +
                   aElementos[iIndice].Valor;
        if (iIndice < High(aElementos)) and
           (LongitudFijaDatos(aElementos[iIndice].Identificador) = 0) then
          ACodigo := ACodigo + GS1_SEPARADOR;
      end;
    end;
  end;
end;

end.
