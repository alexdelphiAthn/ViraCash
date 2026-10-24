{******************************************************************************}
{                                                                              }
{  Módulo:       inLibLineaSku                                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Sincroniza el SKU y sus atributos en las líneas de documentos.           }
{******************************************************************************}
unit inLibLineaSku;

interface

uses
  Data.DB, inLibArticulosAtributosIntf, inLibColumnasSkuIntf;

// Los códigos pueden normalizar signos: «35» no es el rótulo «3,5».
// Se leen los valores enlazados por ID; sin catálogo se conserva el código.
function ValoresLegiblesLineaSku(const AArticulo, ASku: string;
  const ALookup: IArticulosAtributosLookup): TArray<string>;

procedure SincronizarCamposLineaSku(
  ADataSet: TDataSet;
  const ACampos: TCamposColumnasSku;
  const ACodigoArticulo, ACodigoSku: string;
  const ALookup: IArticulosAtributosLookup);

// Actualiza solo las líneas cuyos atributos difieren del SKU.
// El llamador controla permisos de edición y efectos de los eventos Post.
procedure DesempaquetarAtributosLineasSku(
  ADataSet: TDataSet; const ASufijo: string);

implementation

uses
  System.StrUtils, System.SysUtils;

function ValoresLegiblesLineaSku(const AArticulo, ASku: string;
  const ALookup: IArticulosAtributosLookup): TArray<string>;
var
  aValores: TArray<TArticuloAtributoValor>;
  rValor: TArticuloAtributoValor;
begin
  Result := nil;
  aValores := nil;
  if Assigned(ALookup) and (Trim(ASku) <> '') then
    aValores := ALookup.ObtenerAtributosDeSku(ASku);
  if Length(aValores) > 0 then
  begin
    for rValor in aValores do
      Result := Result + [rValor.Valor];
  end
  else if (AArticulo <> '') and StartsText(AArticulo + '/', ASku) then
    Result := Copy(ASku, Length(AArticulo) + 2, MaxInt).Split(['/']);
end;

procedure PonerTexto(ADataSet: TDataSet; const ACampo,
  AValor: string);
var
  oCampo: TField;
begin
  if (ADataSet <> nil) and (ACampo <> '') then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if (oCampo <> nil) and (not oCampo.ReadOnly) then
      oCampo.AsString := AValor;
  end;
end;

procedure PonerEntero(ADataSet: TDataSet; const ACampo: string;
  AValor: Integer);
var
  oCampo: TField;
begin
  if (ADataSet <> nil) and (ACampo <> '') then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if (oCampo <> nil) and (not oCampo.ReadOnly) then
      oCampo.AsInteger := AValor;
  end;
end;

procedure SincronizarCamposLineaSku(
  ADataSet: TDataSet;
  const ACampos: TCamposColumnasSku;
  const ACodigoArticulo, ACodigoSku: string;
  const ALookup: IArticulosAtributosLookup);
var
  aAtributos: TArray<TArticuloAtributo>;
  aPartes: TArray<string>;
  sArticulo, sNombre, sSku, sValor: string;
  i, iNumeroAtributos: Integer;
begin
  if (ADataSet <> nil) and (ADataSet.State in dsEditModes) then
  begin
    sArticulo := Trim(ACodigoArticulo);
    sSku := Trim(ACodigoSku);
    PonerTexto(ADataSet, ACampos.CodigoArt, sArticulo);
    PonerTexto(ADataSet, ACampos.CodigoUnidad, sSku);
    aPartes := ValoresLegiblesLineaSku(sArticulo, sSku, ALookup);
    iNumeroAtributos := Length(aPartes);
    if iNumeroAtributos > 5 then
      iNumeroAtributos := 5;
    aAtributos := nil;
    if Assigned(ALookup) and (sArticulo <> '') then
      aAtributos := ALookup.ObtenerAtributos(sArticulo);
    PonerEntero(ADataSet, ACampos.NumAtributos, iNumeroAtributos);
    for i := 1 to 5 do
    begin
      sValor := '';
      if i <= iNumeroAtributos then
        sValor := Trim(aPartes[i - 1]);
      sNombre := '';
      if i <= Length(aAtributos) then
        sNombre := Trim(aAtributos[i - 1].NombreAtributo);
      PonerTexto(ADataSet, ACampos.AttrValor[i], sValor);
      PonerTexto(ADataSet, ACampos.AttrNombre[i], sNombre);
    end;
  end;
end;

procedure DesempaquetarAtributosLineasSku(
  ADataSet: TDataSet; const ASufijo: string);
var
  aPartes: TArray<string>;
  oMarcador: TBookmark;
  sSku, sEsperado, sCampoNumero: string;
  aCamposValor: array[1..5] of string;
  aValores: array[1..5] of string;
  i: Integer;
  bCambia: Boolean;
begin
  if ADataSet.Active and (not ADataSet.IsEmpty) then
  begin
    sCampoNumero := 'NUM_ATRIBUTOS_' + ASufijo;
    for i := 1 to 5 do
      aCamposValor[i] := 'ATTR' + IntToStr(i) + '_VALOR_' + ASufijo;
    oMarcador := ADataSet.GetBookmark;
    ADataSet.DisableControls;
    try
      ADataSet.First;
      while not ADataSet.Eof do
      begin
        sSku := ADataSet.FieldByName('CODIGO_UNIDAD_' + ASufijo).AsString;
        aPartes := sSku.Split(['/']);
        if Length(aPartes) > 1 then
        begin
          bCambia := ADataSet.FieldByName(sCampoNumero).AsInteger <>
            Length(aPartes) - 1;
          for i := 1 to 5 do
          begin
            if i < Length(aPartes) then
              sEsperado := aPartes[i]
            else
              sEsperado := '';
            aValores[i] := sEsperado;
            if Trim(ADataSet.FieldByName(aCamposValor[i]).AsString) <>
               sEsperado then
              bCambia := True;
          end;
          if bCambia then
          begin
            ADataSet.Edit;
            ADataSet.FieldByName(sCampoNumero).AsInteger :=
              Length(aPartes) - 1;
            for i := 1 to 5 do
              ADataSet.FieldByName(aCamposValor[i]).AsString := aValores[i];
            ADataSet.Post;
          end;
        end;
        ADataSet.Next;
      end;
      if ADataSet.BookmarkValid(oMarcador) then
        ADataSet.GotoBookmark(oMarcador);
    finally
      try
        ADataSet.EnableControls;
      finally
        ADataSet.FreeBookmark(oMarcador);
      end;
    end;
  end;
end;

end.
