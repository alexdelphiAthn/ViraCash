{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArqueoBitacora                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       12/11/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Meteorología y apuntes del cuaderno de bitácora de los días que abarca    }
{    un arqueo de caja. Dominio puro: el ticket de cierre, el histórico de     }
{    arqueos y su listado comparten aquí la selección de días y los textos.    }
{******************************************************************************}
unit inLibArqueoBitacora;

interface

uses
  System.SysUtils, System.Generics.Collections,
  inLibMeteorologiaCajaIntf;

type
  TDiaBitacoraArqueo = record
    Almacen: string;
    Fecha: TDateTime;
    TieneMeteorologia: Boolean;
    Ciudad: string;
    Temperatura: TValorMeteorologiaCaja;
    Minima: TValorMeteorologiaCaja;
    Maxima: TValorMeteorologiaCaja;
    Nubes: TValorMeteorologiaCaja;
    Lluvia: TValorMeteorologiaCaja;
    Apuntes: string;
  end;
  TDiasBitacoraArqueo = TArray<TDiaBitacoraArqueo>;

  // Días con parte meteorológico o apuntes de bitácora. Un almacén vacío
  // devuelve los de todos los almacenes de la empresa. Si la base de datos
  // aún no tiene las tablas, no devuelve ningún día.
  IRepositorioBitacoraArqueo = interface
    ['{4E0B7C55-2B9D-4C0E-9B53-6F2B8B1F2A71}']
    function ListarDiasBitacora(const AEmpresa, AAlmacen: string;
      ADesde, AHasta: TDateTime): TDiasBitacoraArqueo;
  end;

  // Índice por almacén y día para resolver muchos arqueos con una lectura.
  TIndiceBitacoraArqueo = class
  private
    FDias: TDictionary<string, TDiaBitacoraArqueo>;
    function Clave(const AAlmacen: string; AFecha: TDateTime): string;
  public
    constructor Create(const ADias: TDiasBitacoraArqueo);
    destructor Destroy; override;
    function DiasDeArqueo(const AAlmacen: string;
      ADesde, AHasta: TDateTime): TDiasBitacoraArqueo;
  end;

const
  // Un arqueo no debería abarcar más; evita recorrer rangos erróneos.
  MAX_DIAS_BITACORA_ARQUEO = 366;
  FECHA_MINIMA_BITACORA_ARQUEO = 2.0;
  FECHA_MAXIMA_BITACORA_ARQUEO = 2958465.0;

// El arqueo cubre más de un día: los textos llevan la fecha de cada uno.
function ArqueoAbarcaVariosDias(ADesde, AHasta: TDateTime): Boolean;
function TextoValorBitacoraArqueo(
  const AValor: TValorMeteorologiaCaja): string;
// Parte del día en una línea: ciudad, temperaturas, nubes y lluvia.
function ResumenMeteorologiaDia(const ADia: TDiaBitacoraArqueo): string;
// Una línea por día con parte; con fecha delante si AConFecha.
function LineasMeteorologiaArqueo(const ADias: TDiasBitacoraArqueo;
  AConFecha: Boolean): TArray<string>;
// Los apuntes de cada día, con fecha delante si AConFecha.
function LineasApuntesArqueo(const ADias: TDiasBitacoraArqueo;
  AConFecha: Boolean): TArray<string>;
function UnirLineasBitacoraArqueo(const ALineas: TArray<string>;
  const ASeparador: string): string;
// Parte el texto en líneas de AAncho caracteres como máximo, por palabras
// y respetando los saltos de línea escritos por el usuario.
function AjustarTextoAncho(const ATexto: string;
  AAncho: Integer): TArray<string>;

implementation

uses
  System.DateUtils, System.Classes,
  inLibMsgMeteorologiaCaja;

function ArqueoAbarcaVariosDias(ADesde, AHasta: TDateTime): Boolean;
begin
  Result := Trunc(AHasta) > Trunc(ADesde);
end;

function TextoValorBitacoraArqueo(
  const AValor: TValorMeteorologiaCaja): string;
begin
  Result := '-';
  if AValor.TieneValor then
    Result := FormatFloat('0.0', AValor.Valor);
end;

function ResumenMeteorologiaDia(const ADia: TDiaBitacoraArqueo): string;
begin
  Result := '';
  if ADia.TieneMeteorologia then
  begin
    Result := Format(SResumenMeteoBitacoraArqueo,
      [TextoValorBitacoraArqueo(ADia.Temperatura),
       TextoValorBitacoraArqueo(ADia.Minima),
       TextoValorBitacoraArqueo(ADia.Maxima),
       TextoValorBitacoraArqueo(ADia.Nubes),
       TextoValorBitacoraArqueo(ADia.Lluvia)]);
    if Trim(ADia.Ciudad) <> '' then
      Result := Trim(ADia.Ciudad) + ': ' + Result;
  end;
end;

function PrefijoFecha(AFecha: TDateTime; AConFecha: Boolean): string;
begin
  Result := '';
  if AConFecha then
    Result := FormatDateTime('dd/mm', AFecha) + ' ';
end;

procedure Anadir(var ALineas: TArray<string>; const ATexto: string);
var
  iIndice: Integer;
begin
  iIndice := Length(ALineas);
  SetLength(ALineas, iIndice + 1);
  ALineas[iIndice] := ATexto;
end;

function LineasMeteorologiaArqueo(const ADias: TDiasBitacoraArqueo;
  AConFecha: Boolean): TArray<string>;
var
  iDia: Integer;
begin
  Result := nil;
  for iDia := 0 to High(ADias) do
  begin
    if ADias[iDia].TieneMeteorologia then
      Anadir(Result, PrefijoFecha(ADias[iDia].Fecha, AConFecha) +
        ResumenMeteorologiaDia(ADias[iDia]));
  end;
end;

function LineasApuntesArqueo(const ADias: TDiasBitacoraArqueo;
  AConFecha: Boolean): TArray<string>;
var
  iDia: Integer;
  sApuntes: string;
begin
  Result := nil;
  for iDia := 0 to High(ADias) do
  begin
    sApuntes := Trim(ADias[iDia].Apuntes);
    if sApuntes <> '' then
      Anadir(Result, PrefijoFecha(ADias[iDia].Fecha, AConFecha) +
        sApuntes);
  end;
end;

function UnirLineasBitacoraArqueo(const ALineas: TArray<string>;
  const ASeparador: string): string;
begin
  Result := string.Join(ASeparador, ALineas);
end;

procedure AjustarParrafo(var ALineas: TArray<string>;
  const AParrafo: string; AAncho: Integer);
var
  iCorte: Integer;
  sResto: string;
begin
  sResto := TrimRight(AParrafo);
  if sResto = '' then
    Anadir(ALineas, '');
  while sResto <> '' do
  begin
    if Length(sResto) <= AAncho then
    begin
      Anadir(ALineas, sResto);
      sResto := '';
    end
    else
    begin
      iCorte := AAncho + 1;
      while (iCorte > 1) and (sResto[iCorte] <> ' ') do
        Dec(iCorte);
      // Una palabra más larga que la línea se corta por el ancho.
      if iCorte <= 1 then
        iCorte := AAncho + 1;
      Anadir(ALineas, TrimRight(Copy(sResto, 1, iCorte - 1)));
      sResto := TrimLeft(Copy(sResto, iCorte, MaxInt));
    end;
  end;
end;

function AjustarTextoAncho(const ATexto: string;
  AAncho: Integer): TArray<string>;
var
  iAncho: Integer;
  iParrafo: Integer;
  oParrafos: TStringList;
begin
  Result := nil;
  iAncho := AAncho;
  if iAncho < 1 then
    iAncho := 1;
  if Trim(ATexto) <> '' then
  begin
    oParrafos := TStringList.Create;
    try
      oParrafos.Text := Trim(ATexto);
      for iParrafo := 0 to oParrafos.Count - 1 do
        AjustarParrafo(Result, oParrafos[iParrafo], iAncho);
    finally
      FreeAndNil(oParrafos);
    end;
  end;
end;

{ TIndiceBitacoraArqueo }

constructor TIndiceBitacoraArqueo.Create(const ADias: TDiasBitacoraArqueo);
var
  iDia: Integer;
begin
  inherited Create;
  FDias := TDictionary<string, TDiaBitacoraArqueo>.Create;
  for iDia := 0 to High(ADias) do
    FDias.AddOrSetValue(
      Clave(ADias[iDia].Almacen, ADias[iDia].Fecha), ADias[iDia]);
end;

destructor TIndiceBitacoraArqueo.Destroy;
begin
  FreeAndNil(FDias);
  inherited;
end;

function TIndiceBitacoraArqueo.Clave(const AAlmacen: string;
  AFecha: TDateTime): string;
begin
  Result := UpperCase(Trim(AAlmacen)) + '|' + IntToStr(Trunc(AFecha));
end;

function TIndiceBitacoraArqueo.DiasDeArqueo(const AAlmacen: string;
  ADesde, AHasta: TDateTime): TDiasBitacoraArqueo;
var
  iDia: Integer;
  iUltimo: Integer;
  oDia: TDiaBitacoraArqueo;
  iIndice: Integer;
begin
  Result := nil;
  iDia := Trunc(ADesde);
  iUltimo := Trunc(AHasta);
  if iUltimo < iDia then
    iUltimo := iDia;
  if iUltimo - iDia >= MAX_DIAS_BITACORA_ARQUEO then
    iUltimo := iDia + MAX_DIAS_BITACORA_ARQUEO - 1;
  while iDia <= iUltimo do
  begin
    if FDias.TryGetValue(Clave(AAlmacen, iDia), oDia) then
    begin
      iIndice := Length(Result);
      SetLength(Result, iIndice + 1);
      Result[iIndice] := oDia;
    end;
    Inc(iDia);
  end;
end;

end.
