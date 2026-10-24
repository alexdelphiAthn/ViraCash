{******************************************************************************}
{                                                                              }
{  Modulo:       inLibArticulosAltaTarifas                                     }
{    Tipo:       Dominio                                                       }
{ Version:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Reglas del alta masiva de precios de tarifa por SKU: cuando dos           }
{    vigencias se solapan, que combinaciones sku|tarifa estan ocupadas,        }
{    que combinaciones nuevas hay que crear y con que precio y estado          }
{    nacen.                                                                    }
{                                                                              }
{    Sale de TfrmMtoArticulos.btnAddSKUClick, donde vivia mezclado con         }
{    la VCL y no se podia probar. No conoce formularios, DevExpress ni         }
{    UniDAC. Las reglas trabajan sobre records; solo la traduccion final       }
{    conoce TDataSet, y se prueba con un TClientDataSet en memoria             }
{    (PLAN_SOLID.md Fase 3; LIBRO_DE_ESTILO_DELPHI.md 14.4).                   }
{******************************************************************************}
unit inLibArticulosAltaTarifas;

interface

uses
  Data.DB;

const
  // Elemento de la lista de SKUs del modal que representa la fila del
  // propio articulo (CODIGO_UNIDAD_ARTTAR vacio en fza_articulos_tarifas).
  cSkuFilaArticulo = 'ARTÍCULO';

type
  // Vigencia de una fila de tarifa. Hasta solo tiene valor cuando
  // TieneHasta es True; sin "hasta" la vigencia queda abierta.
  TVigenciaTarifa = record
    Desde: TDate;
    TieneHasta: Boolean;
    Hasta: TDate;
  end;

  // Fila ya existente en el dataset de tarifas del articulo que puede
  // ocupar una combinacion sku|tarifa durante la vigencia nueva.
  TFilaTarifaExistente = record
    Sku: string;      // CODIGO_UNIDAD_ARTTAR tal cual ('' = articulo)
    Tarifa: string;
    Vigencia: TVigenciaTarifa;
  end;
  TFilasTarifaExistentes = TArray<TFilaTarifaExistente>;

  // Combinacion nueva que el alta debe crear.
  TCombinacionAltaTarifa = record
    Sku: string;              // '' cuando es la fila del articulo
    EsFilaArticulo: Boolean;
    Tarifa: string;
  end;
  TCombinacionesAltaTarifa = TArray<TCombinacionAltaTarifa>;

  // Valores con los que nace la fila nueva del dataset de tarifas.
  TFilaNuevaTarifa = record
    Sku: string;
    Tarifa: string;
    PrecioSalida: Double;
    PrecioFinal: Double;
    EsActiva: Boolean;
    Vigencia: TVigenciaTarifa;
  end;

// Dos vigencias se solapan cuando ninguna termina antes de que empiece
// la otra. Los limites son inclusivos y un extremo sin "hasta" es
// abierto: alcanza cualquier fecha posterior.
function VigenciasSeSolapan(
  const ANueva, AExistente: TVigenciaTarifa): Boolean;

// Llave de ocupacion de una combinacion: sku y tarifa separados por
// barra vertical. La fila del articulo usa sku vacio.
function LlaveOcupacionTarifa(const ASku, ATarifa: string): string;

// Expande la seleccion del modal (skus x tarifas) descartando las
// combinaciones ocupadas por filas existentes de vigencia solapada y
// los duplicados de la propia seleccion. Conserva el orden de la
// seleccion: por sku y, dentro de cada sku, por tarifa.
function CalcularCombinacionesAltaTarifas(
  const ASkusSeleccionados, ATarifasSeleccionadas: TArray<string>;
  const AExistentes: TFilasTarifaExistentes;
  const AVigenciaNueva: TVigenciaTarifa): TCombinacionesAltaTarifa;

// Compone la fila nueva. La fila del propio articulo nace a precio
// cero e inactiva; la de SKU hereda el precio del padre y solo queda
// activa si ese precio es mayor que cero.
function ComponerFilaNuevaTarifa(
  const ACombinacion: TCombinacionAltaTarifa;
  const APrecioPadre: Double;
  const AVigenciaNueva: TVigenciaTarifa): TFilaNuevaTarifa;

// Traduccion entre el dataset de tarifas del articulo y los records de
// arriba. Conoce TDataSet, no UniDAC ni el formulario: se prueba con
// un TClientDataSet en memoria.
function LeerFilasTarifaExistentes(
  ADataSet: TDataSet): TFilasTarifaExistentes;
procedure EscribirFilaNuevaTarifa(
  ADataSet: TDataSet;
  const AFila: TFilaNuevaTarifa);

// Llaves sku|tarifa omitidas por solapamiento, sin duplicados.
function CombinacionesOmitidasAltaTarifas(
  const ASkusSeleccionados, ATarifasSeleccionadas: TArray<string>;
  const ACreadas: TCombinacionesAltaTarifa): TArray<string>;
function DescribirLlaveTarifa(const ALlave: string): string;

// Solo se pueden cerrar automaticamente las combinaciones cuyos precios
// solapados empiezan antes del nuevo tramo. No altera precios futuros.
function LlavesVigenciasCerrables(
  const AExistentes: TFilasTarifaExistentes;
  const AVigenciaNueva: TVigenciaTarifa;
  const ALlaves: TArray<string>): TArray<string>;
function CerrarVigenciasSolapadas(
  ADataSet: TDataSet;
  const AVigenciaNueva: TVigenciaTarifa;
  const ALlaves: TArray<string>): Integer;

implementation

uses
  System.Classes, System.SysUtils, System.StrUtils;

function VigenciasSeSolapan(
  const ANueva, AExistente: TVigenciaTarifa): Boolean;
var
  bNuevaAlcanza: Boolean;
  bExistenteAlcanza: Boolean;
begin
  // Mismas condiciones que el flujo original del formulario: la nueva
  // alcanza a la existente si no tiene "hasta" o si la existente
  // empieza antes de que la nueva termine; y al reves.
  bNuevaAlcanza :=
    (not ANueva.TieneHasta) or (AExistente.Desde <= ANueva.Hasta);
  bExistenteAlcanza :=
    (not AExistente.TieneHasta) or (ANueva.Desde <= AExistente.Hasta);
  Result := bNuevaAlcanza and bExistenteAlcanza;
end;

function LlaveOcupacionTarifa(const ASku, ATarifa: string): string;
begin
  Result := ASku + '|' + ATarifa;
end;

function CalcularCombinacionesAltaTarifas(
  const ASkusSeleccionados, ATarifasSeleccionadas: TArray<string>;
  const AExistentes: TFilasTarifaExistentes;
  const AVigenciaNueva: TVigenciaTarifa): TCombinacionesAltaTarifa;
var
  Ocupadas: TStringList;
  i, j: Integer;
  iTotal: Integer;
  sSkuFila: string;
  sLlave: string;
begin
  Result := nil;
  iTotal := 0;
  Ocupadas := TStringList.Create;
  try
    Ocupadas.Sorted := True;
    Ocupadas.Duplicates := dupIgnore;
    // Combinaciones ocupadas: filas existentes cuya vigencia solapa
    // con la nueva.
    for i := 0 to High(AExistentes) do
    begin
      if VigenciasSeSolapan(AVigenciaNueva, AExistentes[i].Vigencia) then
        Ocupadas.Add(LlaveOcupacionTarifa(
          AExistentes[i].Sku, AExistentes[i].Tarifa));
    end;
    SetLength(Result,
      Length(ASkusSeleccionados) * Length(ATarifasSeleccionadas));
    for i := 0 to High(ASkusSeleccionados) do
    begin
      for j := 0 to High(ATarifasSeleccionadas) do
      begin
        if ASkusSeleccionados[i] = cSkuFilaArticulo then
          sSkuFila := ''
        else
          sSkuFila := ASkusSeleccionados[i];
        sLlave := LlaveOcupacionTarifa(
          sSkuFila, ATarifasSeleccionadas[j]);
        if Ocupadas.IndexOf(sLlave) = -1 then
        begin
          Result[iTotal].Sku := sSkuFila;
          Result[iTotal].EsFilaArticulo :=
            ASkusSeleccionados[i] = cSkuFilaArticulo;
          Result[iTotal].Tarifa := ATarifasSeleccionadas[j];
          Inc(iTotal);
          // La llave aceptada tambien ocupa: los duplicados de la
          // propia seleccion se generan una sola vez.
          Ocupadas.Add(sLlave);
        end;
      end;
    end;
    SetLength(Result, iTotal);
  finally
    FreeAndNil(Ocupadas);
  end;
end;

function ComponerFilaNuevaTarifa(
  const ACombinacion: TCombinacionAltaTarifa;
  const APrecioPadre: Double;
  const AVigenciaNueva: TVigenciaTarifa): TFilaNuevaTarifa;
var
  fPrecio: Double;
begin
  Result := Default(TFilaNuevaTarifa);
  Result.Sku := ACombinacion.Sku;
  Result.Tarifa := ACombinacion.Tarifa;
  // La fila del articulo ignora el precio del padre: nace a cero.
  if ACombinacion.EsFilaArticulo then
    fPrecio := 0
  else
    fPrecio := APrecioPadre;
  Result.PrecioSalida := fPrecio;
  Result.PrecioFinal := fPrecio;
  Result.EsActiva := fPrecio > 0;
  Result.Vigencia := AVigenciaNueva;
end;

function LeerFilasTarifaExistentes(
  ADataSet: TDataSet): TFilasTarifaExistentes;
var
  iTotal: Integer;
begin
  Result := nil;
  if Assigned(ADataSet) and ADataSet.Active then
  begin
    SetLength(Result, ADataSet.RecordCount);
    iTotal := 0;
    ADataSet.First;
    while not ADataSet.Eof do
    begin
      Result[iTotal].Sku :=
        ADataSet.FieldByName('CODIGO_UNIDAD_ARTTAR').AsString;
      Result[iTotal].Tarifa :=
        ADataSet.FieldByName('CODIGO_TAR_ARTTAR').AsString;
      Result[iTotal].Vigencia.Desde :=
        ADataSet.FieldByName('FECHA_DESDE_ARTTAR').AsDateTime;
      Result[iTotal].Vigencia.TieneHasta :=
        not ADataSet.FieldByName('FECHA_HASTA_ARTTAR').IsNull;
      if Result[iTotal].Vigencia.TieneHasta then
        Result[iTotal].Vigencia.Hasta :=
          ADataSet.FieldByName('FECHA_HASTA_ARTTAR').AsDateTime
      else
        Result[iTotal].Vigencia.Hasta := 0;
      Inc(iTotal);
      ADataSet.Next;
    end;
    SetLength(Result, iTotal);
  end;
end;

procedure EscribirFilaNuevaTarifa(
  ADataSet: TDataSet;
  const AFila: TFilaNuevaTarifa);
begin
  ADataSet.Append;
  ADataSet.FieldByName('CODIGO_UNIDAD_ARTTAR').AsString := AFila.Sku;
  ADataSet.FieldByName('CODIGO_TAR_ARTTAR').AsString := AFila.Tarifa;
  ADataSet.FieldByName('PRECIO_SALIDA_ARTTAR').AsFloat :=
    AFila.PrecioSalida;
  ADataSet.FieldByName('PRECIO_FINAL_ARTTAR').AsFloat :=
    AFila.PrecioFinal;
  ADataSet.FieldByName('ESACTIVO_ARTTAR').AsString :=
    IfThen(AFila.EsActiva, 'S', 'N');
  ADataSet.FieldByName('FECHA_DESDE_ARTTAR').AsDateTime :=
    AFila.Vigencia.Desde;
  if AFila.Vigencia.TieneHasta then
    ADataSet.FieldByName('FECHA_HASTA_ARTTAR').AsDateTime :=
      AFila.Vigencia.Hasta
  else
    ADataSet.FieldByName('FECHA_HASTA_ARTTAR').Clear;
  ADataSet.Post;
end;

function LlaveEnLista(const ALlave: string;
  const ALlaves: TArray<string>): Boolean;
var
  sLlave: string;
begin
  Result := False;
  for sLlave in ALlaves do
    Result := Result or SameText(sLlave, ALlave);
end;

function CombinacionesOmitidasAltaTarifas(
  const ASkusSeleccionados, ATarifasSeleccionadas: TArray<string>;
  const ACreadas: TCombinacionesAltaTarifa): TArray<string>;
var
  oCreadas: TArray<string>;
  i, j: Integer;
  sSku: string;
  sLlave: string;
begin
  Result := nil;
  SetLength(oCreadas, Length(ACreadas));
  for i := 0 to High(ACreadas) do
    oCreadas[i] := LlaveOcupacionTarifa(
      ACreadas[i].Sku, ACreadas[i].Tarifa);
  for i := 0 to High(ASkusSeleccionados) do
    for j := 0 to High(ATarifasSeleccionadas) do
    begin
      if ASkusSeleccionados[i] = cSkuFilaArticulo then
        sSku := ''
      else
        sSku := ASkusSeleccionados[i];
      sLlave := LlaveOcupacionTarifa(sSku, ATarifasSeleccionadas[j]);
      if (not LlaveEnLista(sLlave, oCreadas)) and
         (not LlaveEnLista(sLlave, Result)) then
        Result := Result + [sLlave];
    end;
end;

function DescribirLlaveTarifa(const ALlave: string): string;
var
  iSeparador: Integer;
  sSku: string;
begin
  iSeparador := Pos('|', ALlave);
  sSku := Copy(ALlave, 1, iSeparador - 1);
  if sSku = '' then
    sSku := cSkuFilaArticulo;
  Result := sSku + ' / ' + Copy(ALlave, iSeparador + 1, MaxInt);
end;

function LlavesVigenciasCerrables(
  const AExistentes: TFilasTarifaExistentes;
  const AVigenciaNueva: TVigenciaTarifa;
  const ALlaves: TArray<string>): TArray<string>;
var
  sLlave: string;
  oFila: TFilaTarifaExistente;
  bTieneAnterior: Boolean;
  bTieneBloqueo: Boolean;
begin
  Result := nil;
  for sLlave in ALlaves do
  begin
    bTieneAnterior := False;
    bTieneBloqueo := False;
    for oFila in AExistentes do
      if SameText(LlaveOcupacionTarifa(oFila.Sku, oFila.Tarifa),
           sLlave) and VigenciasSeSolapan(AVigenciaNueva,
           oFila.Vigencia) then
      begin
        if oFila.Vigencia.Desde < AVigenciaNueva.Desde then
          bTieneAnterior := True
        else
          bTieneBloqueo := True;
      end;
    if bTieneAnterior and (not bTieneBloqueo) and
       (not LlaveEnLista(sLlave, Result)) then
      Result := Result + [sLlave];
  end;
end;

function CerrarVigenciasSolapadas(
  ADataSet: TDataSet;
  const AVigenciaNueva: TVigenciaTarifa;
  const ALlaves: TArray<string>): Integer;
var
  oCerrables: TArray<string>;
  oVigencia: TVigenciaTarifa;
  sLlave: string;
begin
  Result := 0;
  if Assigned(ADataSet) and ADataSet.Active then
  begin
    oCerrables := LlavesVigenciasCerrables(
      LeerFilasTarifaExistentes(ADataSet), AVigenciaNueva, ALlaves);
    ADataSet.First;
    while not ADataSet.Eof do
    begin
      sLlave := LlaveOcupacionTarifa(
        ADataSet.FieldByName('CODIGO_UNIDAD_ARTTAR').AsString,
        ADataSet.FieldByName('CODIGO_TAR_ARTTAR').AsString);
      oVigencia.Desde :=
        ADataSet.FieldByName('FECHA_DESDE_ARTTAR').AsDateTime;
      oVigencia.TieneHasta :=
        not ADataSet.FieldByName('FECHA_HASTA_ARTTAR').IsNull;
      oVigencia.Hasta :=
        ADataSet.FieldByName('FECHA_HASTA_ARTTAR').AsDateTime;
      if LlaveEnLista(sLlave, oCerrables) and
         VigenciasSeSolapan(AVigenciaNueva, oVigencia) then
      begin
        ADataSet.Edit;
        ADataSet.FieldByName('FECHA_HASTA_ARTTAR').AsDateTime :=
          AVigenciaNueva.Desde - 1;
        ADataSet.Post;
        Inc(Result);
      end;
      ADataSet.Next;
    end;
  end;
end;

end.
