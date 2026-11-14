{ Periodicidad de descuentos de tarifa. FZ-ISSUE-727. }
unit inLibTarifasPeriodicidad;

interface

type
  TTipoPeriodoTarifa = (pptSemana, pptMes, pptAno);
  TPeriodoTarifa = record
    Tipo: TTipoPeriodoTarifa;
    Desde: Integer;
    Hasta: Integer;
  end;
  TPeriodosTarifa = TArray<TPeriodoTarifa>;

  IRepositorioPeriodicidadTarifa = interface
    ['{E6727C44-D726-41D7-A047-8714C1271727}']
    function Disponible: Boolean;
    function Cargar(const ATarifa: string): TPeriodosTarifa;
    procedure Guardar(const ATarifa: string; const APeriodos: TPeriodosTarifa;
      const AUsuario: string);
    function Vigente(const ATarifa: string; AFecha: TDateTime): Boolean;
  end;

function TarifaInicialConPeriodicidad(const ABase, APromocional: string;
  const ARepositorio: IRepositorioPeriodicidadTarifa;
  AFecha: TDateTime): string;

function TarifaClienteConPeriodicidad(const ACliente, ABase,
  AAutomatica: string): string;

function TextoTipoPeriodoTarifa(ATipo: TTipoPeriodoTarifa): string;
function TipoPeriodoTarifa(const ATexto: string): TTipoPeriodoTarifa;
function ValorDiaPeriodo(ATipo: TTipoPeriodoTarifa;
  const ATexto: string): Integer;
function TextoDiaPeriodo(ATipo: TTipoPeriodoTarifa; AValor: Integer): string;
procedure ValidarPeriodosTarifa(const APeriodos: TPeriodosTarifa);
function CumplePeriodicidadTarifa(const APeriodos: TPeriodosTarifa;
  AFecha: TDateTime): Boolean;

implementation

uses
  System.SysUtils, System.DateUtils, inLibMsgArticulos;

function TarifaInicialConPeriodicidad(const ABase, APromocional: string;
  const ARepositorio: IRepositorioPeriodicidadTarifa;
  AFecha: TDateTime): string;
begin
  Result := ABase;
  if (Trim(APromocional) <> '') and Assigned(ARepositorio) then
    if ARepositorio.Vigente(Trim(APromocional), AFecha) then
      Result := Trim(APromocional);
end;

function TarifaClienteConPeriodicidad(const ACliente, ABase,
  AAutomatica: string): string;
begin
  Result := ACliente;
  if (Trim(ACliente) = '') or SameText(Trim(ACliente), Trim(ABase)) then
    Result := AAutomatica;
end;

const
  DIAS_SEMANA: array[1..7] of string = ('Lunes', 'Martes', 'Miércoles',
    'Jueves', 'Viernes', 'Sábado', 'Domingo');

function TextoTipoPeriodoTarifa(ATipo: TTipoPeriodoTarifa): string;
begin
  case ATipo of
    pptSemana: Result := 'SEMANA';
    pptMes: Result := 'MES';
    pptAno: Result := 'ANO';
  else
    raise EArgumentException.Create(SPeriodicidadErrorTipo);
  end;
end;

function TipoPeriodoTarifa(const ATexto: string): TTipoPeriodoTarifa;
begin
  if SameText(ATexto, 'SEMANA') then
    Result := pptSemana
  else if SameText(ATexto, 'MES') then
    Result := pptMes
  else if SameText(ATexto, 'ANO') then
    Result := pptAno
  else
    raise EArgumentException.Create(SPeriodicidadErrorTipo);
end;

function DiaValido(ATipo: TTipoPeriodoTarifa; AValor: Integer): Boolean;
var
  Fecha: TDateTime;
begin
  case ATipo of
    pptSemana: Result := (AValor >= 1) and (AValor <= 7);
    pptMes: Result := (AValor >= 1) and (AValor <= 31);
    pptAno: Result := (AValor >= 101) and (AValor <= 1231) and
      TryEncodeDate(2000, AValor div 100, AValor mod 100, Fecha);
  else
    Result := False;
  end;
end;

function ValorDiaPeriodo(ATipo: TTipoPeriodoTarifa;
  const ATexto: string): Integer;
var
  I, Separador, Dia, Mes: Integer;
begin
  Result := 0;
  if ATipo = pptSemana then
    for I := Low(DIAS_SEMANA) to High(DIAS_SEMANA) do
      if SameText(Trim(ATexto), DIAS_SEMANA[I]) or
         SameText(Trim(ATexto), TextoDiaPeriodo(pptSemana, I)) then
        Result := I;
  if (ATipo <> pptAno) and (Result = 0) then
    Result := StrToIntDef(Trim(ATexto), 0);
  if ATipo = pptAno then
  begin
    Separador := Pos('/', ATexto);
    Dia := StrToIntDef(Copy(ATexto, 1, Separador - 1), 0);
    Mes := StrToIntDef(Copy(ATexto, Separador + 1, MaxInt), 0);
    Result := Mes * 100 + Dia;
  end;
  if not DiaValido(ATipo, Result) then
    raise EArgumentException.Create(
      SPeriodicidadErrorDia);
end;

function TextoDiaPeriodo(ATipo: TTipoPeriodoTarifa; AValor: Integer): string;
begin
  if not DiaValido(ATipo, AValor) then
    raise EArgumentException.Create(SPeriodicidadErrorDiaPeriodo);
  case ATipo of
    pptSemana:
      case AValor of
        1: Result := SPeriodicidadLunes;
        2: Result := SPeriodicidadMartes;
        3: Result := SPeriodicidadMiercoles;
        4: Result := SPeriodicidadJueves;
        5: Result := SPeriodicidadViernes;
        6: Result := SPeriodicidadSabado;
        7: Result := SPeriodicidadDomingo;
      end;
    pptMes: Result := IntToStr(AValor);
    pptAno: Result := Format('%.2d/%.2d', [AValor mod 100, AValor div 100]);
  end;
end;

procedure ValidarPeriodosTarifa(const APeriodos: TPeriodosTarifa);
var
  I, J: Integer;
begin
  for I := 0 to High(APeriodos) do
  begin
    if not DiaValido(APeriodos[I].Tipo, APeriodos[I].Desde) or
       not DiaValido(APeriodos[I].Tipo, APeriodos[I].Hasta) then
      raise EArgumentException.Create(SPeriodicidadErrorRango);
    for J := 0 to I - 1 do
      if (APeriodos[I].Tipo = APeriodos[J].Tipo) and
         (APeriodos[I].Desde = APeriodos[J].Desde) and
         (APeriodos[I].Hasta = APeriodos[J].Hasta) then
        raise EArgumentException.Create(SPeriodicidadErrorDuplicado);
  end;
end;

function CumplePeriodicidadTarifa(const APeriodos: TPeriodosTarifa;
  AFecha: TDateTime): Boolean;
var
  Periodo: TPeriodoTarifa;
  Valor: Integer;
  Coincide: Boolean;
begin
  if AFecha = 0 then
    AFecha := Date;
  Result := Length(APeriodos) = 0;
  for Periodo in APeriodos do
  begin
    case Periodo.Tipo of
      pptSemana: Valor := DayOfTheWeek(AFecha);
      pptMes: Valor := DayOf(AFecha);
      pptAno: Valor := MonthOf(AFecha) * 100 + DayOf(AFecha);
    else
      Valor := 0;
    end;
    if Periodo.Desde <= Periodo.Hasta then
      Coincide := (Valor >= Periodo.Desde) and (Valor <= Periodo.Hasta)
    else
      Coincide := (Valor >= Periodo.Desde) or (Valor <= Periodo.Hasta);
    Result := Result or Coincide;
  end;
end;

end.
