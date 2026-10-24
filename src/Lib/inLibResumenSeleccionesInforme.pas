{******************************************************************************}
{                                                                              }
{  Módulo:       inLibResumenSeleccionesInforme                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Texto del resumen que encabeza los listados con opciones: las             }
{    selecciones aplicadas (fechas y filtros), quién lo pidió, cuándo y        }
{    cuánto tardaron los datos. No depende de VCL ni de FastReport.            }
{******************************************************************************}
unit inLibResumenSeleccionesInforme;

interface

uses
  System.Classes;

resourcestring
  SResumenSeleccionesPrefijo = 'Selección: ';
  SResumenSeleccionesRangoFechas = 'del %s al %s';
  SResumenSeleccionesSinIndicar = '(sin indicar)';
  SResumenSeleccionesTodos = 'Todos';
  SResumenSeleccionesTodas = 'Todas';
  SResumenSeleccionesNinguna = 'Ninguna';
  SResumenSeleccionesTarifa = 'Tarifa';
  // Criterio de los PRC_GET_BALANCE_ALMACEN_*: va en el resumen de los
  // balances para que nadie lea «Ent. compra» como el coste de esas
  // compras (FZ-ISSUE-440).
  SResumenBalanceValoracion = 'Valoración';
  SResumenBalanceValoracionCriterio =
    'existencias, entradas y demás movimientos al precio medio actual ' +
    '(no al coste de cada compra); ventas a lo facturado sin IVA';
  SResumenSeleccionesSi = 'Sí';
  SResumenSeleccionesNo = 'No';
  SResumenSeleccionesListaRecortada = '%s y %d más (%d en total)';
  SResumenSeleccionesEmision =
    'Solicitado el %s a las %s por %s · Datos obtenidos en %s';
  SResumenSeleccionesSegundos = '%s s';
  SResumenSeleccionesMinutos = '%d min %.2d s';

type
  // Selecciones de un listado en el orden en que se añaden. Cada una se
  // escribe "Etiqueta: valor"; los dos puntos finales de la etiqueta (las
  // de pantalla los llevan) se quitan.
  TResumenSeleccionesInforme = class
  private
    FElementos: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Anadir(const AEtiqueta, AValor: string);
    procedure AnadirRangoFechas(
      const AEtiqueta: string;
      ADesde, AHasta: TDateTime);
    procedure AnadirSiNo(const AEtiqueta: string; AValor: Boolean);
    // Lista vacía = ATextoVacio (Todos si no se indica). Las largas se
    // recortan diciendo cuántos elementos hay en total.
    procedure AnadirLista(
      const AEtiqueta: string;
      AValores: TStrings;
      const ATextoVacio: string = '');
    function EstaVacio: Boolean;
    // Todo en un párrafo (cabecera del informe).
    function Texto: string;
    // Una selección por elemento (hojas de cálculo).
    function Elementos: TArray<string>;
  end;

function TextoDuracionDatosInforme(ADuracionMs: Int64): string;
function TextoEmisionInforme(
  AMomento: TDateTime;
  const AUsuario: string;
  ADuracionMs: Int64): string;

implementation

uses
  System.SysUtils;

const
  SEPARADOR_SELECCIONES = ' · ';
  // Une la etiqueta con su valor: el ajuste de línea no los separa.
  SEPARADOR_ETIQUETA = ':' + #$00A0;
  MAX_ELEMENTOS_LISTA = 8;
  MS_POR_SEGUNDO = 1000;
  MS_DECIMAL_HASTA = 10000;
  SEGUNDOS_POR_MINUTO = 60;

function EtiquetaLimpia(const AEtiqueta: string): string;
begin
  Result := Trim(AEtiqueta);
  while (Result <> '') and (Result[Length(Result)] = ':') do
    Result := Trim(Copy(Result, 1, Length(Result) - 1));
end;

function TextoFecha(AFecha: TDateTime): string;
begin
  // cxDateEdit vacío devuelve NullDate (negativo).
  if AFecha <= 0 then
    Result := SResumenSeleccionesSinIndicar
  else
    Result := DateToStr(AFecha);
end;

{ TResumenSeleccionesInforme }

constructor TResumenSeleccionesInforme.Create;
begin
  inherited Create;
  FElementos := TStringList.Create;
end;

destructor TResumenSeleccionesInforme.Destroy;
begin
  FreeAndNil(FElementos);
  inherited Destroy;
end;

procedure TResumenSeleccionesInforme.Anadir(const AEtiqueta, AValor: string);
var
  sValor: string;
begin
  sValor := Trim(AValor);
  if sValor = '' then
    sValor := SResumenSeleccionesSinIndicar;
  FElementos.Add(EtiquetaLimpia(AEtiqueta) + SEPARADOR_ETIQUETA + sValor);
end;

procedure TResumenSeleccionesInforme.AnadirRangoFechas(
  const AEtiqueta: string;
  ADesde, AHasta: TDateTime);
begin
  Anadir(
    AEtiqueta,
    Format(SResumenSeleccionesRangoFechas,
      [TextoFecha(ADesde), TextoFecha(AHasta)]));
end;

procedure TResumenSeleccionesInforme.AnadirSiNo(
  const AEtiqueta: string;
  AValor: Boolean);
begin
  if AValor then
    Anadir(AEtiqueta, SResumenSeleccionesSi)
  else
    Anadir(AEtiqueta, SResumenSeleccionesNo);
end;

procedure TResumenSeleccionesInforme.AnadirLista(
  const AEtiqueta: string;
  AValores: TStrings;
  const ATextoVacio: string);
var
  i: Integer;
  iTotal: Integer;
  sLista: string;
begin
  iTotal := 0;
  if AValores <> nil then
    iTotal := AValores.Count;
  if iTotal = 0 then
  begin
    if ATextoVacio = '' then
      Anadir(AEtiqueta, SResumenSeleccionesTodos)
    else
      Anadir(AEtiqueta, ATextoVacio);
  end
  else
  begin
    sLista := '';
    for i := 0 to iTotal - 1 do
      if i < MAX_ELEMENTOS_LISTA then
      begin
        if sLista <> '' then
          sLista := sLista + ', ';
        sLista := sLista + Trim(AValores[i]);
      end;
    if iTotal > MAX_ELEMENTOS_LISTA then
      sLista := Format(SResumenSeleccionesListaRecortada,
        [sLista, iTotal - MAX_ELEMENTOS_LISTA, iTotal]);
    Anadir(AEtiqueta, sLista);
  end;
end;

function TResumenSeleccionesInforme.EstaVacio: Boolean;
begin
  Result := FElementos.Count = 0;
end;

function TResumenSeleccionesInforme.Texto: string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to FElementos.Count - 1 do
  begin
    if Result <> '' then
      Result := Result + SEPARADOR_SELECCIONES;
    Result := Result + FElementos[i];
  end;
  if Result <> '' then
    Result := SResumenSeleccionesPrefijo + Result;
end;

function TResumenSeleccionesInforme.Elementos: TArray<string>;
begin
  Result := FElementos.ToStringArray;
end;

function TextoDuracionDatosInforme(ADuracionMs: Int64): string;
var
  iSegundos: Int64;
begin
  if ADuracionMs < 0 then
    ADuracionMs := 0;
  iSegundos := ADuracionMs div MS_POR_SEGUNDO;
  if ADuracionMs < MS_DECIMAL_HASTA then
    Result := Format(SResumenSeleccionesSegundos,
      [FormatFloat('0.0', ADuracionMs / MS_POR_SEGUNDO)])
  else if iSegundos < SEGUNDOS_POR_MINUTO then
    Result := Format(SResumenSeleccionesSegundos, [IntToStr(iSegundos)])
  else
    Result := Format(SResumenSeleccionesMinutos,
      [iSegundos div SEGUNDOS_POR_MINUTO,
       iSegundos mod SEGUNDOS_POR_MINUTO]);
end;

function TextoEmisionInforme(
  AMomento: TDateTime;
  const AUsuario: string;
  ADuracionMs: Int64): string;
var
  sUsuario: string;
begin
  sUsuario := Trim(AUsuario);
  if sUsuario = '' then
    sUsuario := SResumenSeleccionesSinIndicar;
  Result := Format(SResumenSeleccionesEmision,
    [DateToStr(AMomento),
     FormatDateTime('hh:nn:ss', AMomento),
     sUsuario,
     TextoDuracionDatosInforme(ADuracionMs)]);
end;

end.
