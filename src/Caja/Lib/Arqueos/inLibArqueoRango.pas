{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArqueoRango                                              }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       10/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Dominio puro del rango de fechas del arqueo de caja (FZ-ISSUE-408). Los   }
{    cierres se hacen por turno: el rango propuesto empieza donde terminó el   }
{    último cierre del día, y quien no puede cambiar la fecha de caja sí       }
{    puede cambiar la hora, pero no el día.                                    }
{******************************************************************************}
unit inLibArqueoRango;

interface

// «Desde» que se propone al abrir el arqueo: el instante del
// último cierre si queda dentro del rango; si no, el «desde» recibido.
function DesdePropuestoArqueo(ADesde, AHasta: TDateTime;
  AHayCierre: Boolean; AUltimoCierre: TDateTime): TDateTime;
// Para hoy se propone la hora actual. Otro día de caja usa su fin de día.
function HastaPropuestoArqueo(AFechaCaja, AInstanteActual: TDateTime): TDateTime;
// El día fijado con la hora del valor tecleado.
function FijarDiaArqueo(ADiaFijo, AValor: TDateTime): TDateTime;
// El valor tecleado se sale del día fijado.
function CambiaDiaArqueo(ADiaFijo, AValor: TDateTime): Boolean;

// Años admitidos en el rango del arqueo. Un año fuera de aquí es un
// error de tecleo (FZ-ISSUE-994: «1120» en vez de «2026»).
const
  ANIO_MINIMO_ARQUEO = 2000;
  ANIO_MAXIMO_ARQUEO = 2099;

// Lee «dd/mm/aaaa», «dd/mm/aaaa hh:mm» o «dd/mm/aaaa hh:mm:ss», y las
// mismas cifras seguidas (ddmmaaaa o ddmmaaaahhmmss). No completa fechas
// a medias ni admite años fuera del rango del arqueo.
function IntentarLeerFechaHoraArqueo(const ATexto: string;
  out AFecha: TDateTime): Boolean;
function FechaArqueoEnRango(AFecha: TDateTime): Boolean;

implementation

uses
  System.DateUtils, System.SysUtils;

function FechaArqueoEnRango(AFecha: TDateTime): Boolean;
begin
  Result := (YearOf(AFecha) >= ANIO_MINIMO_ARQUEO) and
    (YearOf(AFecha) <= ANIO_MAXIMO_ARQUEO);
end;

// Parte ATexto en números separados por un carácter de ASeparadores.
// Falla si hay un tramo vacío, no numérico o de más de ALongitudMaxima.
function LeerNumerosArqueo(const ATexto: string;
  const ASeparadores: TSysCharSet; ALongitudMaxima: Integer;
  out ANumeros: TArray<Integer>): Boolean;
var
  i, iValor: Integer;
  sTramo: string;
begin
  Result := True;
  ANumeros := nil;
  sTramo := '';
  for i := 1 to Length(ATexto) + 1 do
  begin
    if (i <= Length(ATexto)) and
      not CharInSet(ATexto[i], ASeparadores) then
    begin
      sTramo := sTramo + ATexto[i];
    end
    else
    begin
      Result := Result and (Length(sTramo) <= ALongitudMaxima) and
        TryStrToInt(sTramo, iValor) and (iValor >= 0);
      if Result then
      begin
        ANumeros := ANumeros + [iValor];
      end;
      sTramo := '';
    end;
  end;
end;

function IntentarLeerFechaHoraArqueo(const ATexto: string;
  out AFecha: TDateTime): Boolean;
var
  sTexto, sFecha, sHora: string;
  i, iEspacio: Integer;
  bNumerica: Boolean;
  aPartesDia, aPartesHora: TArray<Integer>;
  dDia, dHora: TDateTime;
begin
  AFecha := 0;
  sTexto := Trim(ATexto);
  bNumerica := (Length(sTexto) = 8) or (Length(sTexto) = 14);
  for i := 1 to Length(sTexto) do
  begin
    bNumerica := bNumerica and CharInSet(sTexto[i], ['0'..'9']);
  end;
  if bNumerica then
  begin
    // Cifras seguidas: ddmmaaaa o ddmmaaaahhmmss.
    sFecha := Copy(sTexto, 1, 2) + '/' + Copy(sTexto, 3, 2) + '/' +
      Copy(sTexto, 5, 4);
    sHora := '';
    if Length(sTexto) = 14 then
    begin
      sHora := Copy(sTexto, 9, 2) + ':' + Copy(sTexto, 11, 2) + ':' +
        Copy(sTexto, 13, 2);
    end;
  end
  else
  begin
    iEspacio := Pos(' ', sTexto);
    if iEspacio = 0 then
    begin
      sFecha := sTexto;
      sHora := '';
    end
    else
    begin
      sFecha := Copy(sTexto, 1, iEspacio - 1);
      sHora := Trim(Copy(sTexto, iEspacio + 1, MaxInt));
    end;
  end;
  // El año se exige con cuatro cifras: «26» o «1120» no son un año válido.
  Result := LeerNumerosArqueo(sFecha, ['/', '-', '.'], 4, aPartesDia) and
    (Length(aPartesDia) = 3) and
    (aPartesDia[2] >= ANIO_MINIMO_ARQUEO) and
    (aPartesDia[2] <= ANIO_MAXIMO_ARQUEO) and
    TryEncodeDate(aPartesDia[2], aPartesDia[1], aPartesDia[0], dDia);
  dHora := 0;
  if Result and (sHora <> '') then
  begin
    Result := LeerNumerosArqueo(sHora, [':'], 2, aPartesHora) and
      (Length(aPartesHora) >= 2) and (Length(aPartesHora) <= 3);
    if Result then
    begin
      if Length(aPartesHora) = 2 then
      begin
        aPartesHora := aPartesHora + [0];
      end;
      Result := TryEncodeTime(aPartesHora[0], aPartesHora[1],
        aPartesHora[2], 0, dHora);
    end;
  end;
  if Result then
  begin
    AFecha := dDia + dHora;
  end;
end;

function DesdePropuestoArqueo(ADesde, AHasta: TDateTime;
  AHayCierre: Boolean; AUltimoCierre: TDateTime): TDateTime;
var
  dSiguiente: TDateTime;
begin
  Result := ADesde;
  if AHayCierre then
  begin
    // Los rangos persistidos tienen ambos extremos incluidos.
    dSiguiente := IncSecond(AUltimoCierre);
    if (CompareDateTime(dSiguiente, ADesde) > 0) and
       (CompareDateTime(dSiguiente, AHasta) < 0) then
      Result := dSiguiente;
  end;
end;

function HastaPropuestoArqueo(AFechaCaja, AInstanteActual: TDateTime): TDateTime;
begin
  if SameDate(AFechaCaja, AInstanteActual) then
    Result := AInstanteActual
  else
    Result := DateOf(AFechaCaja) + EncodeTime(23, 59, 59, 0);
end;

function FijarDiaArqueo(ADiaFijo, AValor: TDateTime): TDateTime;
begin
  Result := DateOf(ADiaFijo) + TimeOf(AValor);
end;

function CambiaDiaArqueo(ADiaFijo, AValor: TDateTime): Boolean;
begin
  Result := not SameDate(ADiaFijo, AValor);
end;

end.
