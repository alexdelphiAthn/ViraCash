{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArqueoDesglose                                          }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Dominio puro del recuento detallado de billetes y monedas del arqueo.     }
{    Analiza la lista de denominaciones parametrizada, calcula los totales     }
{    contados y serializa el desglose al formato "denominacion:unidades;..."   }
{    que persiste DESGLOSE_BILLETES_ARQ y consume el justificante de cierre.   }
{    El texto serializado usa siempre el punto como separador decimal para     }
{    que no dependa de la configuración regional del puesto.                   }
{******************************************************************************}
unit inLibArqueoDesglose;

interface

type
  TTipoDenominacionArqueo = (tdaBillete, tdaMoneda);

  TDenominacionArqueo = record
    Valor: Currency;
    Unidades: Integer;
    function Importe: Currency;
    function Tipo: TTipoDenominacionArqueo;
  end;

  TDesgloseArqueo = TArray<TDenominacionArqueo>;

const
  { Denominaciones de curso legal del euro, de mayor a menor. }
  DenominacionesArqueoPorDefecto =
    '500;200;100;50;20;10;5;2;1;0.50;0.20;0.10;0.05;0.02;0.01';
  { A partir de este valor la denominación se considera billete. }
  ValorMinimoBilleteArqueo = 5;
  SeparadorDenominacionesArqueo = ';';
  SeparadorUnidadesArqueo = ':';

function AnalizarValorDenominacionArqueo(
  const ATexto: string;
  out AValor: Currency): Boolean;
function FormatearValorDenominacionArqueo(AValor: Currency): string;
function AnalizarDenominacionesArqueo(
  const ATexto: string): TArray<Currency>;
function CrearDesgloseArqueo(
  const AValores: TArray<Currency>): TDesgloseArqueo;
function AnalizarDesgloseArqueo(const ATexto: string): TDesgloseArqueo;
function FormatearDesgloseArqueo(
  const ADesglose: TDesgloseArqueo): string;
function TotalDesgloseArqueo(const ADesglose: TDesgloseArqueo): Currency;
function TotalDesgloseArqueoPorTipo(
  const ADesglose: TDesgloseArqueo;
  ATipo: TTipoDenominacionArqueo): Currency;
function UnidadesDesgloseArqueo(
  const ADesglose: TDesgloseArqueo): Integer;

implementation

uses
  System.SysUtils,
  System.Classes;

function TDenominacionArqueo.Importe: Currency;
begin
  Result := Valor * Unidades;
end;

function TDenominacionArqueo.Tipo: TTipoDenominacionArqueo;
begin
  if Valor >= ValorMinimoBilleteArqueo then
    Result := tdaBillete
  else
    Result := tdaMoneda;
end;

function AnalizarValorDenominacionArqueo(
  const ATexto: string;
  out AValor: Currency): Boolean;
var
  sNormalizado: string;
begin
  AValor := 0;
  { Se admiten ambos separadores decimales: el parámetro lo teclea el
    instalador y el texto persistido siempre llega con punto. }
  sNormalizado := StringReplace(
    Trim(ATexto),
    ',',
    '.',
    [rfReplaceAll]);
  Result :=
    (sNormalizado <> '') and
    TryStrToCurr(sNormalizado, AValor, TFormatSettings.Invariant) and
    (AValor > 0);
  if not Result then
    AValor := 0;
end;

function FormatearValorDenominacionArqueo(AValor: Currency): string;
begin
  if AValor = Int(AValor) then
    Result := IntToStr(Trunc(AValor))
  else
    Result := FormatFloat('0.00', AValor, TFormatSettings.Invariant);
end;

function ContieneValorArqueo(
  const AValores: TArray<Currency>;
  AValor: Currency): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to High(AValores) do
    if AValores[i] = AValor then
      Result := True;
end;

procedure OrdenarValoresDescendente(var AValores: TArray<Currency>);
var
  i: Integer;
  j: Integer;
  vAuxiliar: Currency;
begin
  { Listas de una docena larga de elementos: la inserción directa basta y
    evita arrastrar dependencias de comparadores genéricos. }
  for i := 1 to High(AValores) do
  begin
    vAuxiliar := AValores[i];
    j := i - 1;
    while (j >= 0) and (AValores[j] < vAuxiliar) do
    begin
      AValores[j + 1] := AValores[j];
      Dec(j);
    end;
    AValores[j + 1] := vAuxiliar;
  end;
end;

function TrocearTextoArqueo(const ATexto: string): TStringList;
begin
  Result := TStringList.Create;
  Result.StrictDelimiter := True;
  Result.Delimiter := SeparadorDenominacionesArqueo;
  Result.DelimitedText := ATexto;
end;

function AnalizarDenominacionesArqueo(
  const ATexto: string): TArray<Currency>;
var
  iTrozo: Integer;
  oTrozos: TStringList;
  vValor: Currency;
begin
  Result := nil;
  oTrozos := TrocearTextoArqueo(ATexto);
  try
    for iTrozo := 0 to oTrozos.Count - 1 do
      if AnalizarValorDenominacionArqueo(oTrozos[iTrozo], vValor) and
         (not ContieneValorArqueo(Result, vValor)) then
      begin
        SetLength(Result, Length(Result) + 1);
        Result[High(Result)] := vValor;
      end;
  finally
    FreeAndNil(oTrozos);
  end;
  if Length(Result) = 0 then
    Result := AnalizarDenominacionesArqueo(
      DenominacionesArqueoPorDefecto)
  else
    OrdenarValoresDescendente(Result);
end;

function CrearDesgloseArqueo(
  const AValores: TArray<Currency>): TDesgloseArqueo;
var
  i: Integer;
begin
  SetLength(Result, Length(AValores));
  for i := 0 to High(AValores) do
  begin
    Result[i].Valor := AValores[i];
    Result[i].Unidades := 0;
  end;
end;

function AnalizarParDesgloseArqueo(
  const ATexto: string;
  var ADenominacion: TDenominacionArqueo): Boolean;
var
  iSeparador: Integer;
  iUnidades: Integer;
  vValor: Currency;
begin
  iSeparador := Pos(SeparadorUnidadesArqueo, ATexto);
  Result :=
    (iSeparador > 0) and
    AnalizarValorDenominacionArqueo(
      Copy(ATexto, 1, iSeparador - 1),
      vValor) and
    TryStrToInt(
      Trim(Copy(ATexto, iSeparador + 1, MaxInt)),
      iUnidades) and
    (iUnidades > 0);
  if Result then
  begin
    ADenominacion.Valor := vValor;
    ADenominacion.Unidades := iUnidades;
  end;
end;

function AnalizarDesgloseArqueo(const ATexto: string): TDesgloseArqueo;
var
  iTrozo: Integer;
  oDenominacion: TDenominacionArqueo;
  oTrozos: TStringList;
begin
  Result := nil;
  oTrozos := TrocearTextoArqueo(ATexto);
  try
    for iTrozo := 0 to oTrozos.Count - 1 do
      if AnalizarParDesgloseArqueo(oTrozos[iTrozo], oDenominacion) then
      begin
        SetLength(Result, Length(Result) + 1);
        Result[High(Result)] := oDenominacion;
      end;
  finally
    FreeAndNil(oTrozos);
  end;
end;

function FormatearDesgloseArqueo(
  const ADesglose: TDesgloseArqueo): string;
var
  i: Integer;
  oPartes: TStringBuilder;
begin
  oPartes := TStringBuilder.Create;
  try
    for i := 0 to High(ADesglose) do
      if ADesglose[i].Unidades > 0 then
      begin
        if oPartes.Length > 0 then
          oPartes.Append(SeparadorDenominacionesArqueo);
        oPartes.Append(
          FormatearValorDenominacionArqueo(ADesglose[i].Valor));
        oPartes.Append(SeparadorUnidadesArqueo);
        oPartes.Append(IntToStr(ADesglose[i].Unidades));
      end;
    Result := oPartes.ToString;
  finally
    FreeAndNil(oPartes);
  end;
end;

function TotalDesgloseArqueo(const ADesglose: TDesgloseArqueo): Currency;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to High(ADesglose) do
    Result := Result + ADesglose[i].Importe;
end;

function TotalDesgloseArqueoPorTipo(
  const ADesglose: TDesgloseArqueo;
  ATipo: TTipoDenominacionArqueo): Currency;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to High(ADesglose) do
    if ADesglose[i].Tipo = ATipo then
      Result := Result + ADesglose[i].Importe;
end;

function UnidadesDesgloseArqueo(
  const ADesglose: TDesgloseArqueo): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to High(ADesglose) do
    if ADesglose[i].Unidades > 0 then
      Result := Result + ADesglose[i].Unidades;
end;

end.
