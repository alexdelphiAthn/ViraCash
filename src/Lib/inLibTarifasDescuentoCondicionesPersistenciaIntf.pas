{******************************************************************************}
{                                                                              }
{  Modulo:       inLibTarifasDescuentoCondicionesPersistenciaIntf             }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       25/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de datos para limitar el descuento de una tarifa mediante una      }
{    propiedad de tipo LISTA y uno o varios valores.                           }
{******************************************************************************}
unit inLibTarifasDescuentoCondicionesPersistenciaIntf;

interface

type
  TModoCondicionDescuentoTarifa = (
    mcdTodos,
    mcdSoloSi,
    mcdTodosExcepto
  );

  TCondicionDescuentoTarifa = record
    Modo: TModoCondicionDescuentoTarifa;
    CodigoPropiedad: string;
    IdsValores: TArray<Integer>;
  end;

  TPropiedadListaDescuentoTarifa = record
    Codigo: string;
    Nombre: string;
  end;

  TValorListaDescuentoTarifa = record
    Id: Integer;
    Nombre: string;
  end;

  TPropiedadesListaDescuentoTarifa =
    TArray<TPropiedadListaDescuentoTarifa>;
  TValoresListaDescuentoTarifa = TArray<TValorListaDescuentoTarifa>;

  IRepositorioCondicionesDescuentoTarifa = interface
    ['{51817AB3-2932-4D5E-BE67-8722E34524B1}']
    function Cargar(
      const ACodigoTarifa: string): TCondicionDescuentoTarifa;
    function ListarPropiedades: TPropiedadesListaDescuentoTarifa;
    function ListarValores(
      const ACodigoPropiedad: string): TValoresListaDescuentoTarifa;
    procedure Guardar(
      const ACodigoTarifa: string;
      const ACondicion: TCondicionDescuentoTarifa;
      const AUsuario: string);
  end;

function CondicionDescuentoTodos: TCondicionDescuentoTarifa;
function ModoCondicionDescuentoATexto(
  AModo: TModoCondicionDescuentoTarifa): string;
function TextoAModoCondicionDescuento(
  const ATexto: string): TModoCondicionDescuentoTarifa;
procedure ValidarCondicionDescuentoTarifa(
  const ACondicion: TCondicionDescuentoTarifa);

implementation

uses
  System.SysUtils, System.Generics.Collections;

resourcestring
  SErrorModoCondicionDescuento =
    'Modo de aplicación de descuento no válido: %s';
  SErrorPropiedadCondicionObligatoria =
    'Seleccione una propiedad para limitar el descuento';
  SErrorValoresCondicionObligatorios =
    'Seleccione al menos un valor de la propiedad';
  SErrorValorCondicionNoValido =
    'La selección contiene un valor de propiedad no válido';
  SErrorValorCondicionDuplicado =
    'La selección contiene valores de propiedad duplicados';

function CondicionDescuentoTodos: TCondicionDescuentoTarifa;
begin
  Result.Modo := mcdTodos;
  Result.CodigoPropiedad := '';
  SetLength(Result.IdsValores, 0);
end;

function ModoCondicionDescuentoATexto(
  AModo: TModoCondicionDescuentoTarifa): string;
begin
  case AModo of
    mcdTodos:
      Result := 'TODOS';
    mcdSoloSi:
      Result := 'SOLO_SI';
    mcdTodosExcepto:
      Result := 'TODOS_EXCEPTO';
  else
    raise EArgumentOutOfRangeException.CreateFmt(
      SErrorModoCondicionDescuento,
      [IntToStr(Ord(AModo))]);
  end;
end;

function TextoAModoCondicionDescuento(
  const ATexto: string): TModoCondicionDescuentoTarifa;
var
  sModo: string;
begin
  sModo := UpperCase(Trim(ATexto));
  if sModo = 'TODOS' then
    Result := mcdTodos
  else if sModo = 'SOLO_SI' then
    Result := mcdSoloSi
  else if sModo = 'TODOS_EXCEPTO' then
    Result := mcdTodosExcepto
  else
    raise EArgumentException.CreateFmt(
      SErrorModoCondicionDescuento,
      [ATexto]);
end;

procedure ValidarCondicionDescuentoTarifa(
  const ACondicion: TCondicionDescuentoTarifa);
var
  i: Integer;
  oIds: TDictionary<Integer, Boolean>;
begin
  if ACondicion.Modo <> mcdTodos then
  begin
    if Trim(ACondicion.CodigoPropiedad) = '' then
      raise EArgumentException.Create(
        SErrorPropiedadCondicionObligatoria);
    if Length(ACondicion.IdsValores) = 0 then
      raise EArgumentException.Create(
        SErrorValoresCondicionObligatorios);
    oIds := TDictionary<Integer, Boolean>.Create;
    try
      for i := 0 to High(ACondicion.IdsValores) do
      begin
        if ACondicion.IdsValores[i] <= 0 then
          raise EArgumentException.Create(
            SErrorValorCondicionNoValido);
        if oIds.ContainsKey(ACondicion.IdsValores[i]) then
          raise EArgumentException.Create(
            SErrorValorCondicionDuplicado);
        oIds.Add(ACondicion.IdsValores[i], True);
      end;
    finally
      oIds.Free;
    end;
  end;
end;

end.
