{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataDecimalesArticulo                                      }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Decimales de la unidad de un artículo (TIPO_CANTIDAD_ART +                }
{    TUnidadesMedida), con caché por artículo. Lo usan las exportaciones a     }
{    Excel que no traen la unidad en su consulta (balance, FZ-ISSUE-246).      }
{******************************************************************************}
unit UniDataDecimalesArticulo;

interface

uses
  System.SysUtils, Uni, inLibUnidadesMedida;

// Funcion con su propia cache: una consulta por articulo distinto. Vive
// mientras viva la referencia devuelta.
function CrearDecimalesArticuloUniDAC(AConexion: TUniConnection;
  AUnidades: TUnidadesMedida): TDecimalesArticulo;

implementation

uses
  System.Generics.Collections, Data.DB;

type
  IDecimalesArticulo = interface
    ['{3A6F1E52-7C0B-4D1E-9B64-2E8F5A1C7D90}']
    function Decimales(const ACodigoArticulo: string): Integer;
  end;

  TDecimalesArticuloUniDAC = class(TInterfacedObject, IDecimalesArticulo)
  private
    FConexion: TUniConnection;
    FUnidades: TUnidadesMedida;
    FCache: TDictionary<string, Integer>;
  public
    constructor Create(AConexion: TUniConnection;
      AUnidades: TUnidadesMedida);
    destructor Destroy; override;
    function Decimales(const ACodigoArticulo: string): Integer;
  end;

constructor TDecimalesArticuloUniDAC.Create(AConexion: TUniConnection;
  AUnidades: TUnidadesMedida);
begin
  inherited Create;
  FConexion := AConexion;
  FUnidades := AUnidades;
  FCache := TDictionary<string, Integer>.Create;
end;

destructor TDecimalesArticuloUniDAC.Destroy;
begin
  FreeAndNil(FCache);
  inherited;
end;

function TDecimalesArticuloUniDAC.Decimales(
  const ACodigoArticulo: string): Integer;
var
  q: TUniQuery;
  sClave, sUnidad: string;
begin
  Result := 0;
  sClave := UpperCase(Trim(ACodigoArticulo));
  if (sClave <> '') and Assigned(FUnidades) and
     not FCache.TryGetValue(sClave, Result) then
  begin
    sUnidad := '';
    q := TUniQuery.Create(nil);
    try
      q.Connection := FConexion;
      q.SQL.Text :=
        'SELECT TIPO_CANTIDAD_ART FROM fza_articulos ' +
        ' WHERE CODIGO_ART_ART = :ART';
      q.ParamByName('ART').AsString := Trim(ACodigoArticulo);
      q.Open;
      if not q.IsEmpty then
        sUnidad := q.FieldByName('TIPO_CANTIDAD_ART').AsString;
    finally
      q.Free;
    end;
    Result := FUnidades.Decimales(sUnidad);
    FCache.AddOrSetValue(sClave, Result);
  end;
end;

function CrearDecimalesArticuloUniDAC(AConexion: TUniConnection;
  AUnidades: TUnidadesMedida): TDecimalesArticulo;
var
  oDecimales: IDecimalesArticulo;
begin
  oDecimales := TDecimalesArticuloUniDAC.Create(AConexion, AUnidades);
  Result :=
    function(const ACodigoArticulo: string): Integer
    begin
      Result := oDecimales.Decimales(ACodigoArticulo);
    end;
end;

end.
