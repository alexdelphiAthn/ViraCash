{******************************************************************************}
{                                                                              }
{  Módulo:       inLibEtiquetasLotes                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Etiquetas por lote y por unidad (F-LOTEC-022): sobre las filas por SKU    }
{    de cdsEtiquetasArt, una etiqueta por unidad de cada lote o serie. La      }
{    serie va en el código de barras (Code128, decisión 3); lote y caducidad   }
{    en LOTE_ETI / CADUCIDAD_ETI y, compuestos, en TEXTO_LOTE_ETI: los       }
{    imprime el diseño que los tenga (el original, desde FZ-ISSUE-603).      }
{    COD_TEMPORADA conserva su valor. Sin lote sale como antes.              }
{******************************************************************************}
unit inLibEtiquetasLotes;

interface

uses
  Data.DB, Datasnap.DBClient, inLibEtiquetasImpresion,
  inLibLotesPersistenciaIntf;

const
  CAMPO_LOTE_ETIQUETA = 'LOTE_ETI';
  CAMPO_CADUCIDAD_ETIQUETA = 'CADUCIDAD_ETI';
  // TextoLoteEtiqueta ya compuesto; vacío en las etiquetas sin lote.
  CAMPO_TEXTO_LOTE_ETIQUETA = 'TEXTO_LOTE_ETI';

type
  // TipoLote: 'L' lote, 'S' serie (TIPO_LOT).
  TLoteEtiqueta = record
    Sku: string;
    Lote: string;
    TipoLote: string;
    Caducidad: TDateTime;
    Copias: Integer;
    CodigoBarras: string;
  end;
  TLotesEtiquetas = TArray<TLoteEtiqueta>;

// Texto que se imprime para el lote: «Lote L1 · Cad. 24/10/2026»,
// «S/N 3569…».
function TextoLoteEtiqueta(const ALote: TLoteEtiqueta): string;

// Lote o serie de la pestaña «Lotes / Series» de la ficha: una etiqueta
// por unidad entera en stock de esa fila (una si es serie o si no llega a
// una unidad), con su caducidad.
function LoteEtiquetaDeArticulo(const ALote: TLoteArticulo): TLoteEtiqueta;

// Como ExpandirEtiquetasPorCantidades, pero cada lote de ALotes saca sus
// copias con su lote (y, si es serie, con la serie como código de barras);
// el resto de la cantidad del SKU sale sin lote. Sin lotes, igual que
// ExpandirEtiquetasPorCantidades.
procedure ExpandirEtiquetasConLotes(ADataSet: TClientDataSet;
  ACantidades: TCantidadesEtiquetas; const ALotes: TLotesEtiquetas);

implementation

uses
  System.SysUtils, System.Variants, inLibMsgLotesConsultas,
  inLibTrazabilidad;

type
  TFilaEtiqueta = TArray<Variant>;

const
  CAMPO_SKU = 'CODIGO_UNIDAD_SKU';
  CAMPO_STOCK = 'STOCK_FILTRADO';
  CAMPO_CODIGO_BARRAS = 'CODIGO_BARRAS_CB';
  TIPO_SERIE = 'S';
  LONGITUD_LOTE_CON_PREFIJO = 8;

function TextoLoteEtiqueta(const ALote: TLoteEtiqueta): string;
begin
  if ALote.TipoLote = TIPO_SERIE then
    Result := Format(SEtiquetaSerie, [ALote.Lote])
  else
  begin
    Result := Format(SEtiquetaLote, [ALote.Lote]);
    // Con caducidad y un lote largo (más de 8 caracteres) el prefijo
    // «Lote » no cabe en la etiqueta original junto a la fecha.
    if (ALote.Caducidad > 0) and
       (Length(ALote.Lote) > LONGITUD_LOTE_CON_PREFIJO) then
      Result := ALote.Lote;
    if ALote.Caducidad > 0 then
      // Año con dos cifras: «Lote QA-L005 cad. 20/10/26» cabe en la
      // etiqueta original; con el año entero se cortaba la fecha.
      Result := Result + Format(SEtiquetaCaducidad,
        [FormatDateTime('dd/mm/yy', ALote.Caducidad)]);
  end;
end;

function LoteEtiquetaDeArticulo(const ALote: TLoteArticulo): TLoteEtiqueta;
begin
  Result := Default(TLoteEtiqueta);
  Result.Sku := ALote.CodigoSku;
  Result.Lote := ALote.Lote;
  Result.TipoLote := TipoCatalogoDeModo(ALote.Modo);
  Result.Caducidad := ALote.FechaCaducidad;
  Result.Copias := 1;
  if (ALote.Modo <> mtSerie) and (ALote.Stock >= 1) then
    Result.Copias := Trunc(ALote.Stock);
end;

function LeerFila(ADataSet: TDataSet): TFilaEtiqueta;
var
  iCampo: Integer;
begin
  SetLength(Result, ADataSet.FieldCount);
  for iCampo := 0 to ADataSet.FieldCount - 1 do
    Result[iCampo] := ADataSet.Fields[iCampo].Value;
end;

procedure AsignarCampo(ADataSet: TDataSet; const ACampo: string;
  const AValor: Variant);
var
  oCampo: TField;
begin
  oCampo := ADataSet.FindField(ACampo);
  if Assigned(oCampo) then
    oCampo.Value := AValor;
end;

procedure AnadirCopias(ADataSet: TClientDataSet; const AFila: TFilaEtiqueta;
  ACopias, ACantidadSku: Integer; const ALote: TLoteEtiqueta;
  AConLote: Boolean);
var
  iCopia: Integer;
  iCampo: Integer;
begin
  for iCopia := 1 to ACopias do
  begin
    ADataSet.Append;
    for iCampo := 0 to ADataSet.FieldCount - 1 do
      ADataSet.Fields[iCampo].Value := AFila[iCampo];
    AsignarCampo(ADataSet, CAMPO_STOCK, ACantidadSku);
    if AConLote then
    begin
      AsignarCampo(ADataSet, CAMPO_LOTE_ETIQUETA, ALote.Lote);
      if ALote.Caducidad > 0 then
        AsignarCampo(ADataSet, CAMPO_CADUCIDAD_ETIQUETA,
          FormatDateTime('dd/mm/yyyy', ALote.Caducidad));
      AsignarCampo(ADataSet, CAMPO_TEXTO_LOTE_ETIQUETA,
        TextoLoteEtiqueta(ALote));
      // El diseño decide si imprime lote y caducidad en sus campos propios.
      if ALote.CodigoBarras <> '' then
        AsignarCampo(ADataSet, CAMPO_CODIGO_BARRAS, ALote.CodigoBarras)
      else if ALote.TipoLote = TIPO_SERIE then
        AsignarCampo(ADataSet, CAMPO_CODIGO_BARRAS, ALote.Lote);
    end;
    ADataSet.Post;
  end;
end;

procedure AnadirSku(ADataSet: TClientDataSet; const AFila: TFilaEtiqueta;
  ACantidad: Integer; const ALotes: TLotesEtiquetas; const ASku: string);
var
  Lote: TLoteEtiqueta;
  iRestante: Integer;
begin
  iRestante := ACantidad;
  for Lote in ALotes do
  begin
    if SameText(Lote.Sku, ASku) and (Lote.Copias > 0) then
    begin
      AnadirCopias(ADataSet, AFila, Lote.Copias, ACantidad, Lote, True);
      Dec(iRestante, Lote.Copias);
    end;
  end;
  if iRestante > 0 then
    AnadirCopias(ADataSet, AFila, iRestante, ACantidad,
      Default(TLoteEtiqueta), False);
end;

procedure ExpandirEtiquetasConLotes(ADataSet: TClientDataSet;
  ACantidades: TCantidadesEtiquetas; const ALotes: TLotesEtiquetas);
var
  aFilas: TArray<TFilaEtiqueta>;
  iFila: Integer;
  iIndiceSku: Integer;
  iCantidad: Integer;
  sSku: string;
begin
  if (Length(ALotes) = 0) or not Assigned(ADataSet) or
     not ADataSet.Active or (ADataSet.FindField(CAMPO_SKU) = nil) then
    ExpandirEtiquetasPorCantidades(ADataSet, ACantidades)
  else
  begin
    ADataSet.DisableControls;
    ADataSet.DisableConstraints;
    try
      for iFila := 0 to ADataSet.FieldCount - 1 do
      begin
        ADataSet.Fields[iFila].ReadOnly := False;
        ADataSet.Fields[iFila].Required := False;
      end;
      iIndiceSku := ADataSet.FieldByName(CAMPO_SKU).Index;
      SetLength(aFilas, 0);
      ADataSet.First;
      while not ADataSet.Eof do
      begin
        aFilas := aFilas + [LeerFila(ADataSet)];
        ADataSet.Next;
      end;
      ADataSet.EmptyDataSet;
      for iFila := 0 to High(aFilas) do
      begin
        sSku := VarToStr(aFilas[iFila][iIndiceSku]);
        if not ACantidades.TryGetValue(sSku, iCantidad) then
          iCantidad := 0;
        AnadirSku(ADataSet, aFilas[iFila], iCantidad, ALotes, sSku);
      end;
    finally
      ADataSet.EnableConstraints;
      ADataSet.EnableControls;
    end;
    ADataSet.First;
  end;
end;

end.
