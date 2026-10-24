{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataResolutorSkuRecuento                                   }
{    Tipo:       Persistencia                                                  }
{ Versión:       1.0.0                                                         }
{   Fecha:       08/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Consultas UniDAC de IResolutorSkuRecuento: SKU existente y SKU de un      }
{    código de barras (FZ-ISSUE-351).                                          }
{******************************************************************************}
unit UniDataResolutorSkuRecuento;

interface

uses
  Uni,
  inLibRecuentoSkuNormalizacion;

function CrearResolutorSkuRecuentoUniDAC(
  AConexion: TUniConnection): IResolutorSkuRecuento;

implementation

uses
  System.SysUtils,
  Data.DB;

type
  TResolutorSkuRecuentoUniDAC = class(
    TInterfacedObject, IResolutorSkuRecuento)
  private
    FConexion: TUniConnection;
    function PrimerValor(const ASql, AValor: string): string;
  public
    constructor Create(AConexion: TUniConnection);
    function SkuExiste(const ASku: string): Boolean;
    function SkuDeCodigoBarras(const ACodigo: string): string;
  end;

function CrearResolutorSkuRecuentoUniDAC(
  AConexion: TUniConnection): IResolutorSkuRecuento;
begin
  Result := TResolutorSkuRecuentoUniDAC.Create(AConexion);
end;

constructor TResolutorSkuRecuentoUniDAC.Create(AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

// Primera columna de la primera fila; vacío sin filas o sin valor.
function TResolutorSkuRecuentoUniDAC.PrimerValor(
  const ASql, AValor: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  if Trim(AValor) <> '' then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text := ASql;
      oConsulta.ParamByName('VALOR').AsString := Trim(AValor);
      oConsulta.Open;
      if not oConsulta.IsEmpty then
        Result := Trim(oConsulta.Fields[0].AsString);
      oConsulta.Close;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TResolutorSkuRecuentoUniDAC.SkuExiste(const ASku: string): Boolean;
begin
  Result := PrimerValor(
    'SELECT CODIGO_UNIDAD_SKU FROM fza_articulos_skus ' +
    ' WHERE CODIGO_UNIDAD_SKU = :VALOR LIMIT 1',
    ASku) <> '';
end;

function TResolutorSkuRecuentoUniDAC.SkuDeCodigoBarras(
  const ACodigo: string): string;
begin
  Result := PrimerValor(
    'SELECT CODIGO_UNIDAD_CB FROM fza_codigos_barras ' +
    ' WHERE CODIGO_BARRAS_CB = :VALOR LIMIT 1',
    ACodigo);
end;

end.
