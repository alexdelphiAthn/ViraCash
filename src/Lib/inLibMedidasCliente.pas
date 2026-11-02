{******************************************************************************}
{  Módulo: inLibMedidasCliente. Tipo: Librería. Fecha: 02/11/2026               }
{  Descripción: Sesiones versionadas; desconocido y cero son distintos.        }
{******************************************************************************}
unit inLibMedidasCliente;

interface

type
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
    Fecha: TDateTime;
    Valores: TMedidasCliente;
    AceptaFueraRango: Boolean;
  end;
  TSesionesMedidasCliente = TArray<TSesionMedidasCliente>;

function ValidarSesionMedidas(const ASesion: TSesionMedidasCliente;
  const AMagnitudes: TMagnitudesCliente): string;
function TextoSesionMedidas(const ASesion: TSesionMedidasCliente): string;

implementation

uses
  System.SysUtils, inLibMsgMedidasCliente;

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
