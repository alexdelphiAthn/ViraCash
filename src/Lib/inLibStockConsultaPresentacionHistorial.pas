{******************************************************************************}
{                                                                              }
{  Modulo:       inLibStockConsultaPresentacionHistorial                       }
{    Tipo:       Colaborador de presentacion                                   }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Historial de articulos visitados en la consulta de stock. Estado puro:    }
{    sin VCL y sin persistencia, para poder probar la navegacion atras /       }
{    adelante y el truncado de la rama futura.                                 }
{******************************************************************************}
unit inLibStockConsultaPresentacionHistorial;

interface

uses
  System.Classes;

type
  THistorialArticulosStock = class
  private
    FArticulos: TStringList;
    FPosicion: Integer;
    FMoviendo: Boolean;
    function GetCuenta: Integer;
    function GetArticulo(AIndice: Integer): string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Limpiar;
    procedure Registrar(const ACodigoArticulo: string);
    function PuedeAnterior: Boolean;
    function PuedeSiguiente: Boolean;
    function Anterior: string;
    function Siguiente: string;
    function Actual: string;
    property Moviendo: Boolean read FMoviendo write FMoviendo;
    property Posicion: Integer read FPosicion;
    property Cuenta: Integer read GetCuenta;
    property Articulos[AIndice: Integer]: string read GetArticulo;
  end;

implementation

uses
  System.SysUtils;

constructor THistorialArticulosStock.Create;
begin
  inherited Create;
  FArticulos := TStringList.Create;
  FPosicion := -1;
  FMoviendo := False;
end;

destructor THistorialArticulosStock.Destroy;
begin
  FreeAndNil(FArticulos);
  inherited Destroy;
end;

function THistorialArticulosStock.GetCuenta: Integer;
begin
  Result := FArticulos.Count;
end;

function THistorialArticulosStock.GetArticulo(AIndice: Integer): string;
begin
  if (AIndice >= 0) and (AIndice < FArticulos.Count) then
    Result := FArticulos[AIndice]
  else
    Result := '';
end;

procedure THistorialArticulosStock.Limpiar;
begin
  FArticulos.Clear;
  FPosicion := -1;
end;

// Al registrar un articulo nuevo se descarta la rama "adelante": el
// historial se comporta como el de un navegador. Repetir el articulo
// actual no genera entrada, y navegando (Moviendo) no se registra nada.
procedure THistorialArticulosStock.Registrar(
  const ACodigoArticulo: string);
begin
  if (not FMoviendo) and (Trim(ACodigoArticulo) <> '') then
  begin
    if (FPosicion < 0) or
       (not SameText(FArticulos[FPosicion], ACodigoArticulo)) then
    begin
      while FArticulos.Count - 1 > FPosicion do
        FArticulos.Delete(FArticulos.Count - 1);
      FArticulos.Add(ACodigoArticulo);
      FPosicion := FArticulos.Count - 1;
    end;
  end;
end;

function THistorialArticulosStock.PuedeAnterior: Boolean;
begin
  Result := FPosicion > 0;
end;

function THistorialArticulosStock.PuedeSiguiente: Boolean;
begin
  Result := FPosicion < FArticulos.Count - 1;
end;

function THistorialArticulosStock.Actual: string;
begin
  Result := GetArticulo(FPosicion);
end;

function THistorialArticulosStock.Anterior: string;
begin
  Result := '';
  if PuedeAnterior then
  begin
    Dec(FPosicion);
    Result := FArticulos[FPosicion];
  end;
end;

function THistorialArticulosStock.Siguiente: string;
begin
  Result := '';
  if PuedeSiguiente then
  begin
    Inc(FPosicion);
    Result := FArticulos[FPosicion];
  end;
end;

end.
