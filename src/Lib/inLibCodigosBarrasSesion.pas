{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCodigosBarrasSesion                                      }
{  Versión:      1.0.0                                                         }
{  Fecha:        06/11/2026                                                    }
{  Autor:        Alejandro Laorden Hidalgo                                     }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:  Códigos de barras de fabricante en sesiones de compra.        }
{******************************************************************************}
unit inLibCodigosBarrasSesion;

interface

uses
  System.SysUtils;

type
  TCombinacionBarrasSesion = record
    Linea: Integer;
    IdFila: Integer;
    IdPivot: Integer;
    Articulo: string;
    ModeloProveedor: string;
    Descripcion: string;
    Color: string;
    Pestana: string;
    Talla: string;
    Codigo: string;
  end;
  TCombinacionesBarrasSesion = TArray<TCombinacionBarrasSesion>;
  TFilasCsvBarras = TArray<TArray<string>>;

function LeerCsvBarras(const ATexto: string;
  ASeparador: Char): TFilasCsvBarras;
function DetectarSeparadorBarras(const ATexto: string): Char;
procedure ValidarCodigoBarrasSesion(const ACodigo: string);
function TipoCodigoBarrasSesion(const ACodigo: string): string;
function ColorCombinacionBarras(const AValor: TCombinacionBarrasSesion): string;

function ImportarCsvBarrasSesion(const AFilas: TFilasCsvBarras;
  const AOriginales: TCombinacionesBarrasSesion; APrimeraFila,
  AColCodigo, AColArticulo, AColColor, AColTalla: Integer;
  const AColorFijo: string = '';
  AUsarModeloProveedor: Boolean = False): TCombinacionesBarrasSesion;

implementation

uses
  System.Generics.Collections, inLibEAN13, inLibMsgBarrasSesion;

function ImportarCsvBarrasSesion(const AFilas: TFilasCsvBarras;
  const AOriginales: TCombinacionesBarrasSesion; APrimeraFila,
  AColCodigo, AColArticulo, AColColor, AColTalla: Integer;
  const AColorFijo: string;
  AUsarModeloProveedor: Boolean): TCombinacionesBarrasSesion;
var
  i, j, k, n: Integer;
  sCodigo, sArticulo, sColor, sTalla: string;
  aUsadas: TArray<Boolean>;

  function CoincideArticulo(const AValor: TCombinacionBarrasSesion): Boolean;
  begin
    if AUsarModeloProveedor then
      Result := SameText(Trim(AValor.ModeloProveedor), sArticulo)
    else
      Result := SameText(Trim(AValor.Articulo), sArticulo);
  end;

  function Campo(AColumna: Integer): string;
  begin
    Result := '';
    if AColumna >= 0 then
    begin
      if AColumna >= Length(AFilas[i]) then
        raise EArgumentException.Create(SBarrasFilaIncompleta);
      Result := Trim(AFilas[i][AColumna]);
    end;
  end;

begin
  if (AColCodigo < 0) or (AColArticulo < 0) then
    raise EArgumentException.Create(SBarrasColumnasObligatorias);
  if (AColCodigo = AColArticulo) or
    ((AColColor >= 0) and ((AColColor = AColCodigo) or
      (AColColor = AColArticulo))) or
    ((AColTalla >= 0) and ((AColTalla = AColCodigo) or
      (AColTalla = AColArticulo) or (AColTalla = AColColor))) then
    raise EArgumentException.Create(SBarrasColumnasRepetidas);
  if (APrimeraFila < 0) or (APrimeraFila >= Length(AFilas)) then
    raise EArgumentException.Create(SBarrasCsvVacio);
  Result := Copy(AOriginales);
  SetLength(aUsadas, Length(AOriginales));
  for i := APrimeraFila to High(AFilas) do
  begin
    try
      sCodigo := Campo(AColCodigo);
      sArticulo := Campo(AColArticulo);
      if sArticulo = '' then
        raise EArgumentException.Create(SBarrasIdentificadorVacio);
      sColor := Campo(AColColor);
      if AColColor < 0 then
        sColor := Trim(AColorFijo);
      sTalla := Campo(AColTalla);
      if sCodigo = '' then
        raise EArgumentException.Create(SBarrasVacio);
      ValidarCodigoBarrasSesion(sCodigo);
      n := -1;
      for j := 0 to High(AOriginales) do
        if CoincideArticulo(AOriginales[j]) and
          (((AColColor < 0) and (sColor = '')) or
            SameText(Trim(ColorCombinacionBarras(AOriginales[j])), sColor)
            or ((sColor = '') and (AOriginales[j].Color = '') and
              (AOriginales[j].Pestana = ''))) and
          ((AColTalla < 0) or
            SameText(Trim(AOriginales[j].Talla), sTalla)) then
        begin
          if n >= 0 then
            raise EArgumentException.Create(SBarrasAmbiguaCsv);
          n := j;
        end;
      if n < 0 then
        raise EArgumentException.CreateFmt(SBarrasSinCoincidencia,
          [sArticulo, sColor, sTalla]);
      if aUsadas[n] then
        raise EArgumentException.CreateFmt(SBarrasDuplicado, [sCodigo]);
      if (Result[n].Codigo <> '') and
        not SameText(Result[n].Codigo, sCodigo) then
        raise EArgumentException.Create(SBarrasOcupada);
      for k := 0 to High(Result) do
        if (k <> n) and SameText(Result[k].Codigo, sCodigo) then
          raise EArgumentException.CreateFmt(SBarrasDuplicado, [sCodigo]);
      Result[n].Codigo := sCodigo;
      aUsadas[n] := True;
    except
      on E: EArgumentException do
        raise EArgumentException.CreateFmt(SBarrasErrorFila,
          [i + 1, E.Message]);
    end;
  end;
end;

procedure ValidarCodigoBarrasSesion(const ACodigo: string);
var
  c: Char;
begin
  if Length(ACodigo) > 50 then
    raise EArgumentException.Create(SBarrasCodigoLargo);
  for c in ACodigo do
    if (Ord(c) < 32) or (Ord(c) = 127) then
      raise EArgumentException.Create(SBarrasCodigoControl);
end;

function TipoCodigoBarrasSesion(const ACodigo: string): string;
var
  c: Char;
  bNumerico: Boolean;
begin
  bNumerico := ACodigo <> '';
  for c in ACodigo do
    bNumerico := bNumerico and CharInSet(c, ['0'..'9']);
  Result := 'CODE128';
  if bNumerico and (Length(ACodigo) = 13) then
    if CalcularDigitoEAN13(Copy(ACodigo, 1, 12)) = ACodigo[13] then
      Result := 'EAN13';
end;

function ColorCombinacionBarras(const AValor: TCombinacionBarrasSesion): string;
begin
  Result := AValor.Color;
  if AValor.Pestana <> '' then
    Result := Result + ' / ' + AValor.Pestana;
  if Result = '' then
    Result := SBarrasSinColor;
end;

type
  TLectorCsvBarras = class
  private
    FTexto: string;
    FSeparador: Char;
    FFilas: TList<TArray<string>>;
    FCampos: TList<string>;
    FCampo: string;
    FIndice: Integer;
    FComillas: Boolean;
    FCerrado: Boolean;
    procedure TerminarCampo;
    procedure TerminarFila;
    procedure LeerEntreComillas;
    procedure ProcesarCaracter;
  public
    constructor Create(const ATexto: string; ASeparador: Char);
    destructor Destroy; override;
    function Ejecutar: TFilasCsvBarras;
  end;

constructor TLectorCsvBarras.Create(const ATexto: string; ASeparador: Char);
begin
  inherited Create;
  FTexto := ATexto;
  FSeparador := ASeparador;
  FFilas := TList<TArray<string>>.Create;
  FCampos := TList<string>.Create;
end;

destructor TLectorCsvBarras.Destroy;
begin
  FreeAndNil(FCampos);
  FreeAndNil(FFilas);
  inherited;
end;

procedure TLectorCsvBarras.TerminarCampo;
begin
  FCampos.Add(FCampo);
  FCampo := '';
  FCerrado := False;
end;

procedure TLectorCsvBarras.TerminarFila;
begin
  TerminarCampo;
  if (FCampos.Count > 1) or (FCampos[0] <> '') then
    FFilas.Add(FCampos.ToArray);
  FCampos.Clear;
end;

procedure TLectorCsvBarras.LeerEntreComillas;
begin
  if FTexto[FIndice] = '"' then
  begin
    if (FIndice < Length(FTexto)) and (FTexto[FIndice + 1] = '"') then
    begin
      FCampo := FCampo + '"';
      Inc(FIndice);
    end
    else
    begin
      FComillas := False;
      FCerrado := True;
    end;
  end
  else
    FCampo := FCampo + FTexto[FIndice];
end;

procedure TLectorCsvBarras.ProcesarCaracter;
var
  c: Char;
begin
  c := FTexto[FIndice];
  if FComillas then
    LeerEntreComillas
  else if c = FSeparador then
    TerminarCampo
  else if CharInSet(c, [#10, #13]) then
  begin
    TerminarFila;
    if (c = #13) and (FIndice < Length(FTexto)) then
      if FTexto[FIndice + 1] = #10 then
        Inc(FIndice);
  end
  else if (c = '"') and (FCampo = '') and not FCerrado then
    FComillas := True
  else if FCerrado or (c = '"') then
    raise EArgumentException.Create(SBarrasCsvComillas)
  else
    FCampo := FCampo + c;
end;

function TLectorCsvBarras.Ejecutar: TFilasCsvBarras;
begin
  FIndice := 1;
  if (FTexto <> '') and (FTexto[1] = #$FEFF) then
    Inc(FIndice);
  while FIndice <= Length(FTexto) do
  begin
    ProcesarCaracter;
    Inc(FIndice);
  end;
  if FComillas then
    raise EArgumentException.Create(SBarrasCsvComillas);
  if (FCampo <> '') or (FCampos.Count > 0) or FCerrado then
    TerminarFila;
  Result := FFilas.ToArray;
end;

function LeerCsvBarras(const ATexto: string;
  ASeparador: Char): TFilasCsvBarras;
var
  oLector: TLectorCsvBarras;
begin
  oLector := TLectorCsvBarras.Create(ATexto, ASeparador);
  try
    Result := oLector.Ejecutar;
  finally
    FreeAndNil(oLector);
  end;
end;

function DetectarSeparadorBarras(const ATexto: string): Char;
var
  i, n, iMejor: Integer;
  c: Char;
  bComillas: Boolean;
  aCuenta: array[0..2] of Integer;
const
  SEPARADORES: array[0..2] of Char = (';', ',', #9);
begin
  for n := 0 to 2 do
    aCuenta[n] := 0;
  bComillas := False;
  i := 1;
  while (i <= Length(ATexto)) and
    (bComillas or not CharInSet(ATexto[i], [#10, #13])) do
  begin
    c := ATexto[i];
    if c = '"' then
      bComillas := not bComillas;
    if not bComillas then
      for n := 0 to 2 do
        if c = SEPARADORES[n] then
          Inc(aCuenta[n]);
    Inc(i);
  end;
  iMejor := 0;
  for n := 1 to 2 do
    if aCuenta[n] > aCuenta[iMejor] then
      iMejor := n;
  Result := SEPARADORES[iMejor];
end;

end.
