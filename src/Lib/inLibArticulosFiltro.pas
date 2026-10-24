unit inLibArticulosFiltro;

{
  Construccion pura del filtro de carga de articulos. No conoce controles
  ni datasets, por lo que se puede caracterizar con pruebas unitarias.
}

interface

type
  TEstadoFiltroArticulos = (
    efaTodos,
    efaActivos,
    efaInactivos
  );

  TFiltroArticulos = record
    Estado: TEstadoFiltroArticulos;
    SoloConStock: Boolean;
    TemporadasCsv: string;
    ProveedoresCsv: string;
    FamiliasCsv: string;
  end;

function SepararValoresFiltroArticulos(
  const ACsv: string): TArray<string>;

// Filtros que no son los de por defecto (solo activos, sin exigir stock,
// sin temporadas, proveedores ni familias), en minúsculas y unidos con
// ' · '. Vacío con el filtro por defecto.
function ResumenFiltroArticulos(const AFiltro: TFiltroArticulos): string;

// Cabecera de la persiana: plegada y con filtros, ACabecera seguida del
// resumen entre paréntesis; si no, ACabecera tal cual.
function CabeceraFiltrosCargaArticulos(const ACabecera: string;
  AExpandida: Boolean; const AFiltro: TFiltroArticulos): string;

implementation

uses
  System.SysUtils,
  System.Classes,
  inLibMsgArticulos;

const
  SEPARADOR_RESUMEN = ' ' + #$00B7 + ' ';

function ResumenFiltroArticulos(const AFiltro: TFiltroArticulos): string;
var
  aPartes: TArray<string>;
  aTemporadas: TArray<string>;
  iCantidad: Integer;
  procedure Agregar(const AParte: string);
  begin
    SetLength(aPartes, Length(aPartes) + 1);
    aPartes[High(aPartes)] := AParte;
  end;
begin
  aPartes := nil;
  case AFiltro.Estado of
    efaTodos:
      Agregar(SResumenFiltroArticulosTodos);
    efaInactivos:
      Agregar(SResumenFiltroArticulosInactivos);
  end;
  if AFiltro.SoloConStock then
    Agregar(SResumenFiltroArticulosConStock);
  aTemporadas := SepararValoresFiltroArticulos(AFiltro.TemporadasCsv);
  if Length(aTemporadas) = 1 then
    Agregar(Format(SResumenFiltroArticulosTemporada, [aTemporadas[0]]))
  else if Length(aTemporadas) > 1 then
    Agregar(Format(SResumenFiltroArticulosTemporadas, [Length(aTemporadas)]));
  iCantidad := Length(SepararValoresFiltroArticulos(AFiltro.ProveedoresCsv));
  if iCantidad > 0 then
    Agregar(Format(SResumenFiltroArticulosProveedores, [iCantidad]));
  iCantidad := Length(SepararValoresFiltroArticulos(AFiltro.FamiliasCsv));
  if iCantidad > 0 then
    Agregar(Format(SResumenFiltroArticulosFamilias, [iCantidad]));
  Result := string.Join(SEPARADOR_RESUMEN, aPartes);
end;

function CabeceraFiltrosCargaArticulos(const ACabecera: string;
  AExpandida: Boolean; const AFiltro: TFiltroArticulos): string;
var
  sResumen: string;
begin
  Result := ACabecera;
  if not AExpandida then
  begin
    sResumen := ResumenFiltroArticulos(AFiltro);
    if sResumen <> '' then
      Result := Format(SCaptionFiltrosCargaArticulosActivos,
        [ACabecera, sResumen]);
  end;
end;

function SepararValoresFiltroArticulos(
  const ACsv: string): TArray<string>;
var
  Lista: TStringList;
  iIndice: Integer;
  sValor: string;
begin
  Result := nil;
  if Trim(ACsv) <> '' then
  begin
    Lista := TStringList.Create;
    try
      Lista.Delimiter := ';';
      Lista.StrictDelimiter := True;
      Lista.DelimitedText := ACsv;
      for iIndice := 0 to Lista.Count - 1 do
      begin
        sValor := Trim(Lista[iIndice]);
        if sValor <> '' then
        begin
          SetLength(Result, Length(Result) + 1);
          Result[High(Result)] := sValor;
        end;
      end;
    finally
      FreeAndNil(Lista);
    end;
  end;
end;

end.
