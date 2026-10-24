{******************************************************************************}
{                                                                              }
{  Módulo:       inLibEtiquetasImpresion                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Piezas comunes de las etiquetas de artículo (FZ-ISSUE-093/098/101):       }
{    una fila por unidad a partir de las cantidades de un documento,           }
{    aviso antes de imprimir (sin etiquetas, SKU sin precio en la tarifa       }
{    —FZ-ISSUE-118—, SKU sin código de barras) y                               }
{    ocultación en el informe del código de barras vacío o todo ceros.         }
{******************************************************************************}
unit inLibEtiquetasImpresion;

interface

uses
  System.Generics.Collections, Data.DB, Datasnap.DBClient, frxClass;

type
  // Unidades a etiquetar por SKU (clave: CODIGO_UNIDAD_SKU).
  TCantidadesEtiquetas = TDictionary<string, Integer>;

// Deja en ADataSet una fila por unidad: cada SKU se repite tantas veces
// como diga ACantidades y los SKU sin cantidad desaparecen. Conserva el
// orden de las filas; STOCK_FILTRADO pasa a valer la cantidad del SKU.
procedure ExpandirEtiquetasPorCantidades(ADataSet: TClientDataSet;
  ACantidades: TCantidadesEtiquetas);
// Lista para un IN (...) SQL con los SKU de ACantidades, entrecomillados.
function SkusEtiquetasCsv(ACantidades: TCantidadesEtiquetas): string;
// Vacío, solo espacios o solo ceros: no identifica ningún SKU.
function EsCodigoBarrasVacio(const ACodigo: string): Boolean;
// SKU distintos de ADataSet cuyo CODIGO_BARRAS_CB está vacío.
function ContarSkusSinCodigoBarras(ADataSet: TDataSet): Integer;
// Etiqueta activa sin fila de precio en la tarifa elegida (FZ-ISSUE-118).
function EsEtiquetaSinPrecio(ADataSet: TDataSet): Boolean;
// Borra de ADataSet las etiquetas sin precio en la tarifa elegida.
procedure QuitarEtiquetasSinPrecio(ADataSet: TDataSet);
// Para el OnBeforePrint del informe: oculta los TfrxBarCodeView cuyo
// valor está vacío o es todo ceros (FastReport pintaba el Text de diseño,
// «0000000000000», que el lector acepta).
procedure OcultarCodigoBarrasVacio(AComponente: TfrxReportComponent);
// Antes de preparar el informe: avisa y aborta si no hay ninguna
// etiqueta; si hay SKU sin precio en la tarifa, ofrece omitirlos o
// cancelar; si hay SKU sin código de barras, pregunta si seguir.
// Devuelve True si se han omitido los SKU sin precio: el modal repite
// QuitarEtiquetasSinPrecio cuando reconstruye el dataset con las guías.
function ComprobarEtiquetasAntesDeImprimir(ADataSet: TDataSet): Boolean;

implementation

uses
  System.SysUtils, System.Variants, System.UITypes, Vcl.Dialogs,
  frxBarcode, inLibMensajesVcl, inLibMsgArticulos;

type
  TFilasEtiquetas = TArray<TArray<Variant>>;

const
  CAMPO_SKU = 'CODIGO_UNIDAD_SKU';
  CAMPO_STOCK = 'STOCK_FILTRADO';
  CAMPO_CODIGO_BARRAS = 'CODIGO_BARRAS_CB';
  CAMPO_PRECIO_FINAL = 'PRECIO_FINAL_ARTTAR';
  CAMPO_PRECIO_SALIDA = 'PRECIO_SALIDA_ARTTAR';
  CAMPO_NOMBRE_TARIFA = 'NOMBRE_TAR_TAR';
  CAMPO_CODIGO_TARIFA = 'CODIGO_TAR_ARTTAR';
  MAXIMO_SKUS_SIN_PRECIO_LISTADOS = 5;

procedure LiberarCamposEtiquetas(ADataSet: TClientDataSet);
var
  iCampo: Integer;
begin
  for iCampo := 0 to ADataSet.FieldCount - 1 do
  begin
    ADataSet.Fields[iCampo].ReadOnly := False;
    ADataSet.Fields[iCampo].Required := False;
  end;
end;

function CapturarFilasEtiquetas(ADataSet: TClientDataSet): TFilasEtiquetas;
var
  iCampo: Integer;
  iFila: Integer;
begin
  SetLength(Result, ADataSet.RecordCount);
  ADataSet.First;
  for iFila := 0 to High(Result) do
  begin
    SetLength(Result[iFila], ADataSet.FieldCount);
    for iCampo := 0 to ADataSet.FieldCount - 1 do
      Result[iFila][iCampo] := ADataSet.Fields[iCampo].Value;
    ADataSet.Next;
  end;
end;

procedure InsertarCopiasEtiquetas(ADataSet: TClientDataSet;
  const AFilas: TFilasEtiquetas; ACantidades: TCantidadesEtiquetas);
var
  iCampo: Integer;
  iCopia: Integer;
  iCantidad: Integer;
  iFila: Integer;
  iIndiceSku: Integer;
  iIndiceStock: Integer;
begin
  iIndiceSku := ADataSet.FieldByName(CAMPO_SKU).Index;
  iIndiceStock := -1;
  if ADataSet.FindField(CAMPO_STOCK) <> nil then
    iIndiceStock := ADataSet.FieldByName(CAMPO_STOCK).Index;
  ADataSet.EmptyDataSet;
  for iFila := 0 to High(AFilas) do
  begin
    if not ACantidades.TryGetValue(
      VarToStr(AFilas[iFila][iIndiceSku]), iCantidad) then
      iCantidad := 0;
    for iCopia := 1 to iCantidad do
    begin
      ADataSet.Append;
      for iCampo := 0 to ADataSet.FieldCount - 1 do
        ADataSet.Fields[iCampo].Value := AFilas[iFila][iCampo];
      if iIndiceStock >= 0 then
        ADataSet.Fields[iIndiceStock].AsInteger := iCantidad;
      ADataSet.Post;
    end;
  end;
end;

procedure ExpandirEtiquetasPorCantidades(ADataSet: TClientDataSet;
  ACantidades: TCantidadesEtiquetas);
begin
  if Assigned(ADataSet) and ADataSet.Active then
  begin
    if ADataSet.IsEmpty or (ADataSet.FindField(CAMPO_SKU) = nil) then
      ADataSet.EmptyDataSet
    else
    begin
      ADataSet.DisableControls;
      ADataSet.DisableConstraints;
      try
        LiberarCamposEtiquetas(ADataSet);
        InsertarCopiasEtiquetas(ADataSet, CapturarFilasEtiquetas(ADataSet),
          ACantidades);
      finally
        ADataSet.EnableConstraints;
        ADataSet.EnableControls;
      end;
    end;
    ADataSet.First;
  end;
end;

function SkusEtiquetasCsv(ACantidades: TCantidadesEtiquetas): string;
var
  sSku: string;
begin
  Result := '';
  for sSku in ACantidades.Keys do
  begin
    if Result <> '' then
      Result := Result + ',';
    Result := Result + QuotedStr(sSku);
  end;
end;

function EsCodigoBarrasVacio(const ACodigo: string): Boolean;
begin
  Result := StringReplace(Trim(ACodigo), '0', '', [rfReplaceAll]) = '';
end;

function ContarSkusSinCodigoBarras(ADataSet: TDataSet): Integer;
var
  oSkus: TDictionary<string, Boolean>;
  oCampoSku: TField;
  oCampoCodigo: TField;
begin
  Result := 0;
  oCampoSku := nil;
  oCampoCodigo := nil;
  if Assigned(ADataSet) and ADataSet.Active then
  begin
    oCampoSku := ADataSet.FindField(CAMPO_SKU);
    oCampoCodigo := ADataSet.FindField(CAMPO_CODIGO_BARRAS);
  end;
  if Assigned(oCampoSku) and Assigned(oCampoCodigo) then
  begin
    oSkus := TDictionary<string, Boolean>.Create;
    ADataSet.DisableControls;
    try
      ADataSet.First;
      while not ADataSet.Eof do
      begin
        if EsCodigoBarrasVacio(oCampoCodigo.AsString) then
          oSkus.AddOrSetValue(oCampoSku.AsString, True);
        ADataSet.Next;
      end;
      ADataSet.First;
      Result := oSkus.Count;
    finally
      ADataSet.EnableControls;
      FreeAndNil(oSkus);
    end;
  end;
end;

function EsEtiquetaSinPrecio(ADataSet: TDataSet): Boolean;
var
  oPrecioFinal: TField;
  oPrecioSalida: TField;
begin
  // El LEFT JOIN con fza_articulos_tarifas deja ambos precios a NULL
  // cuando la tarifa no tiene fila vigente para el SKU ni para el padre.
  oPrecioFinal := ADataSet.FindField(CAMPO_PRECIO_FINAL);
  oPrecioSalida := ADataSet.FindField(CAMPO_PRECIO_SALIDA);
  Result := Assigned(oPrecioFinal) and Assigned(oPrecioSalida) and
            oPrecioFinal.IsNull and oPrecioSalida.IsNull;
end;

procedure QuitarEtiquetasSinPrecio(ADataSet: TDataSet);
begin
  if Assigned(ADataSet) and ADataSet.Active then
  begin
    ADataSet.DisableControls;
    try
      ADataSet.First;
      while not ADataSet.Eof do
      begin
        if EsEtiquetaSinPrecio(ADataSet) then
          ADataSet.Delete
        else
          ADataSet.Next;
      end;
      ADataSet.First;
    finally
      ADataSet.EnableControls;
    end;
  end;
end;

// SKU distintos sin precio, en el orden de las etiquetas. AHayConPrecio
// indica si queda alguna etiqueta con precio.
function SkusSinPrecio(ADataSet: TDataSet;
  out AHayConPrecio: Boolean): TArray<string>;
var
  oVistos: TDictionary<string, Boolean>;
  oSkus: TList<string>;
  sSku: string;
begin
  AHayConPrecio := False;
  oVistos := TDictionary<string, Boolean>.Create;
  oSkus := TList<string>.Create;
  ADataSet.DisableControls;
  try
    ADataSet.First;
    while not ADataSet.Eof do
    begin
      sSku := ADataSet.FieldByName(CAMPO_SKU).AsString;
      if not EsEtiquetaSinPrecio(ADataSet) then
        AHayConPrecio := True
      else if not oVistos.ContainsKey(sSku) then
      begin
        oVistos.Add(sSku, True);
        oSkus.Add(sSku);
      end;
      ADataSet.Next;
    end;
    ADataSet.First;
    Result := oSkus.ToArray;
  finally
    ADataSet.EnableControls;
    FreeAndNil(oSkus);
    FreeAndNil(oVistos);
  end;
end;

function NombreTarifaEtiquetas(ADataSet: TDataSet): string;
var
  oCampo: TField;
begin
  Result := '';
  oCampo := ADataSet.FindField(CAMPO_NOMBRE_TARIFA);
  if Assigned(oCampo) then
    Result := Trim(oCampo.AsString);
  oCampo := ADataSet.FindField(CAMPO_CODIGO_TARIFA);
  if (Result = '') and Assigned(oCampo) then
    Result := Trim(oCampo.AsString);
end;

function DescribirSkusSinPrecio(const ASkus: TArray<string>): string;
var
  iSku: Integer;
begin
  Result := '';
  for iSku := 0 to High(ASkus) do
  begin
    if iSku < MAXIMO_SKUS_SIN_PRECIO_LISTADOS then
    begin
      if Result <> '' then
        Result := Result + ', ';
      Result := Result + ASkus[iSku];
    end;
  end;
  if Length(ASkus) > MAXIMO_SKUS_SIN_PRECIO_LISTADOS then
    Result := Result + ', …';
end;

// FZ-ISSUE-118: sin fila en la tarifa elegida la etiqueta salía con el
// rótulo y sin importe. Se ofrece omitirlas o cancelar.
function OmitirEtiquetasSinPrecio(ADataSet: TDataSet): Boolean;
var
  aSkus: TArray<string>;
  bHayConPrecio: Boolean;
  sTarifa: string;
begin
  Result := False;
  if Assigned(ADataSet.FindField(CAMPO_SKU)) then
  begin
    aSkus := SkusSinPrecio(ADataSet, bHayConPrecio);
    sTarifa := NombreTarifaEtiquetas(ADataSet);
    if (Length(aSkus) > 0) and (not bHayConPrecio) then
    begin
      ShowMessage_fza(Format(SAvisoEtiquetasNingunSkuConPrecio,
        [sTarifa]));
      Abort;
    end;
    if Length(aSkus) > 0 then
    begin
      if MessageDlg_fza(Format(SPreguntaEtiquetasSkusSinPrecio,
           [Length(aSkus), sTarifa, DescribirSkusSinPrecio(aSkus)]),
           mtWarning, [mbYes, mbNo], 0) <> mrYes then
        Abort;
      QuitarEtiquetasSinPrecio(ADataSet);
      Result := True;
    end;
  end;
end;

function ValorCodigoBarras(ACodigo: TfrxBarCodeView): string;
begin
  if ACodigo.IsDataField then
    Result := VarToStr(ACodigo.DataSet.Value[ACodigo.DataField])
  else if (ACodigo.Expression <> '') and Assigned(ACodigo.Report) then
    Result := VarToStr(ACodigo.Report.Calc(ACodigo.Expression))
  else
    Result := ACodigo.Text;
end;

procedure OcultarCodigoBarrasVacio(AComponente: TfrxReportComponent);
var
  oCodigo: TfrxBarCodeView;
begin
  // El evento llega antes de GetData: se evalúa la expresión del registro
  // activo. Con Visible = False FastReport tampoco llama a GetData.
  if AComponente is TfrxBarCodeView then
  begin
    oCodigo := TfrxBarCodeView(AComponente);
    oCodigo.Visible := not EsCodigoBarrasVacio(ValorCodigoBarras(oCodigo));
  end;
end;

function ComprobarEtiquetasAntesDeImprimir(ADataSet: TDataSet): Boolean;
var
  iSinCodigo: Integer;
begin
  if (not Assigned(ADataSet)) or (not ADataSet.Active) or
     ADataSet.IsEmpty then
  begin
    ShowMessage_fza(SAvisoEtiquetasSinUnidades);
    Abort;
  end;
  Result := OmitirEtiquetasSinPrecio(ADataSet);
  iSinCodigo := ContarSkusSinCodigoBarras(ADataSet);
  if (iSinCodigo > 0) and
     (MessageDlg_fza(Format(SPreguntaEtiquetasSkusSinCodigoBarras,
       [iSinCodigo]), mtConfirmation, [mbYes, mbNo], 0) <> mrYes) then
    Abort;
end;

end.
