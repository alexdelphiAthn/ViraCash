{******************************************************************************}
{                                                                              }
{  Decisiones puras del editor de lineas de caja.                              }
{                                                                              }
{******************************************************************************}
unit inMtoCajaEditorLineasDecisiones;

interface

uses
  System.Variants;

function ResolverCodigoConsultaStock(
  const ACodigoEntrada, AArticuloLinea: string;
  ATodosColores, ALineasActivas: Boolean): string;
function ResolverTextoBusqueda(
  const ATexto: string;
  ASelStart, ASelLength: Integer): string;
function DebeBuscarIncremental(const ATexto: string): Boolean;
function DebeUsarSoloTexto(
  const AValor: Variant;
  AEsCeldaEnfocada: Boolean): Boolean;

implementation

uses
  System.SysUtils;

function ResolverCodigoConsultaStock(
  const ACodigoEntrada, AArticuloLinea: string;
  ATodosColores, ALineasActivas: Boolean): string;
begin
  Result := Trim(ACodigoEntrada);
  if ATodosColores and ALineasActivas and
     (Pos('/', Result) > 0) and
     (Trim(AArticuloLinea) <> '') then
    Result := Trim(AArticuloLinea);
end;

function ResolverTextoBusqueda(
  const ATexto: string;
  ASelStart, ASelLength: Integer): string;
begin
  if ASelLength > 0 then
    Result := Copy(ATexto, 1, ASelStart)
  else
    Result := ATexto;
  Result := Trim(Result);
end;

function DebeBuscarIncremental(const ATexto: string): Boolean;
begin
  Result := Trim(ATexto) <> '';
end;

function DebeUsarSoloTexto(
  const AValor: Variant;
  AEsCeldaEnfocada: Boolean): Boolean;
begin
  Result := ((not VarIsNull(AValor)) and
    (Trim(VarToStr(AValor)) <> '')) or
    (not AEsCeldaEnfocada);
end;

end.
