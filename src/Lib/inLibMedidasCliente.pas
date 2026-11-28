{******************************************************************************}
{  Módulo: inLibMedidasCliente. Tipo: Librería. Fecha: 02/11/2026               }
{  Descripción: Sesiones versionadas; desconocido y cero son distintos.        }
{******************************************************************************}
unit inLibMedidasCliente;

interface

type
  TFichaMedidas = (fmCompleta, fmPieIzquierdo, fmPieDerecho, fmTraje, fmRopa);
  TMagnitudCliente = record
    Codigo, Nombre, Unidad: string;
    Minimo, Maximo: Currency;
  end;
  TMagnitudesCliente = TArray<TMagnitudCliente>;
  TMedidaCliente = record
    Codigo, Nombre, Unidad: string;
    Conocida: Boolean;
    Valor: Currency;
  end;
  TMedidasCliente = TArray<TMedidaCliente>;
  TSesionMedidasCliente = record
    Id, Cliente, Persona, Origen, Motivo, Observaciones, Usuario: string;
    // Código del empleado que mide; Persona conserva su nombre de entonces.
    // Vacío en las sesiones anteriores a FZ-ISSUE-1320.
    Empleado: string;
    Fecha: TDateTime;
    Valores: TMedidasCliente;
    AceptaFueraRango: Boolean;
  end;
  TSesionesMedidasCliente = TArray<TSesionMedidasCliente>;

function ValidarSesionMedidas(const ASesion: TSesionMedidasCliente;
  const AMagnitudes: TMagnitudesCliente): string;
function TextoSesionMedidas(const ASesion: TSesionMedidasCliente): string;
function TituloFichaMedidas(AFicha: TFichaMedidas): string;
function IncluyeMagnitud(AFicha: TFichaMedidas; const ACodigo: string): Boolean;
function MarcaMagnitud(AFicha: TFichaMedidas; const ACodigo: string): Integer;

implementation

uses
  System.SysUtils, inLibMsgMedidasCliente;

function TituloFichaMedidas(AFicha: TFichaMedidas): string;
begin
  case AFicha of
    fmPieIzquierdo: Result := SMedidasPieIzquierdo;
    fmPieDerecho: Result := SMedidasPieDerecho;
    fmTraje: Result := SMedidasTraje;
    fmRopa: Result := SMedidasRopa;
  else
    Result := SMedidasTitulo;
  end;
end;

function MarcaMagnitud(AFicha: TFichaMedidas; const ACodigo: string): Integer;
const
  Pie: array[1..3] of string = ('PIE_LARGO_', 'PIE_ANCHO_', 'PIE_EMPEINE_');
  Ropa: array[1..5] of string = ('HOMBROS', 'PECHO', 'CINTURA', 'MANGA', 'LARGO');
var
  i: Integer;
  Lado: string;
begin
  Result := 0;
  case AFicha of
    fmPieIzquierdo, fmPieDerecho:
      begin
        if AFicha = fmPieIzquierdo then Lado := 'I' else Lado := 'D';
        for i := Low(Pie) to High(Pie) do
          if SameText(ACodigo, Pie[i] + Lado) then Result := i;
      end;
    fmTraje, fmRopa:
    begin
      for i := Low(Ropa) to High(Ropa) do
        if SameText(ACodigo, Ropa[i]) then Result := i;
      if (AFicha = fmRopa) and SameText(ACodigo, 'ROPA_CADERA') then
        Result := 6;
    end;
  end;
end;

function IncluyeMagnitud(AFicha: TFichaMedidas; const ACodigo: string): Boolean;
var
  Codigo: string;
begin
  Codigo := UpperCase(ACodigo);
  case AFicha of
    fmPieIzquierdo: Result := Codigo.StartsWith('PIE_') and Codigo.EndsWith('_I');
    fmPieDerecho: Result := Codigo.StartsWith('PIE_') and Codigo.EndsWith('_D');
    fmTraje: Result := (MarcaMagnitud(AFicha, Codigo) > 0) or
      Codigo.StartsWith('TRAJE_');
    fmRopa: Result := (MarcaMagnitud(AFicha, Codigo) > 0) or
      Codigo.StartsWith('ROPA_') or Codigo.StartsWith('TRAJE_');
  else
    Result := True;
  end;
end;

function ValidarSesionMedidas(const ASesion: TSesionMedidasCliente;
  const AMagnitudes: TMagnitudesCliente): string;
var
  rValor: TMedidaCliente;
  rMagnitud: TMagnitudCliente;
  bEncontrada: Boolean;
  sCodigos: string;
begin
  Result := '';
  if (Trim(ASesion.Cliente) = '') or (Trim(ASesion.Persona) = '') or
     (ASesion.Fecha <= 0) or (Length(ASesion.Valores) = 0) then
    raise EArgumentException.Create(SMedidasDatosObligatorios);
  if Trim(ASesion.Empleado) = '' then
    raise EArgumentException.Create(SMedidasEmpleadoInvalido);
  if (ASesion.Origen <> '') and (Trim(ASesion.Motivo) = '') then
    raise EArgumentException.Create(SMedidasMotivoCorreccion);
  sCodigos := '|';
  for rValor in ASesion.Valores do
  begin
    bEncontrada := False;
    if (rValor.Codigo = '') or (Pos('|', rValor.Codigo) > 0) or
       (Pos('|' + rValor.Codigo + '|', sCodigos) > 0) then
      raise EArgumentException.Create(SMedidasMagnitudInvalida);
    sCodigos := sCodigos + rValor.Codigo + '|';
    for rMagnitud in AMagnitudes do
      if rValor.Codigo = rMagnitud.Codigo then
      begin
        bEncontrada := True;
        if rValor.Conocida and (rValor.Valor < 0) then
          raise EArgumentException.Create(SMedidasValorNegativo);
        if rValor.Conocida and ((rValor.Valor < rMagnitud.Minimo) or
           (rValor.Valor > rMagnitud.Maximo)) then
          Result := Result + rMagnitud.Nombre + sLineBreak;
      end;
    if not bEncontrada then
      raise EArgumentException.Create(SMedidasMagnitudInvalida);
  end;
end;

function TextoSesionMedidas(const ASesion: TSesionMedidasCliente): string;
var
  rValor: TMedidaCliente;
  sValor: string;
begin
  Result := DateToStr(ASesion.Fecha) + ' - ' + ASesion.Persona + sLineBreak;
  for rValor in ASesion.Valores do
  begin
    sValor := SMedidasDesconocida;
    if rValor.Conocida then
      sValor := FormatCurr('0.00', rValor.Valor) + ' ' + rValor.Unidad;
    Result := Result + rValor.Nombre + ': ' + sValor + sLineBreak;
  end;
  Result := Result + ASesion.Observaciones;
end;

end.
