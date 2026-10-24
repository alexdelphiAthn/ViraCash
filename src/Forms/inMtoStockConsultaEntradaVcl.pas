{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoStockConsultaEntradaVcl                                  }
{    Tipo:       Adaptador VCL                                                 }
{ Version:       1.1.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Adapta la entrada de articulos de la consulta de stock: el repositorio    }
{    traduce el lector de catalogos a coincidencias y la vista se resuelve     }
{    con cierres. Ninguno recibe el formulario.                                }
{******************************************************************************}
unit inMtoStockConsultaEntradaVcl;

interface

uses
  inLibStockConsultaEntradaIntf,
  inLibStockConsultaPersistenciaIntf;

type
  TAplicarArticuloEntradaStock = reference to procedure(
    const ACodigoArticulo, ACodigoSku: string);
  TMostrarCoincidenciasEntradaStock = reference to procedure(
    const ACoincidencias: TCoincidenciasEntradaStock;
    const AEntrada: string);
  TMostrarEntradaStockNoEncontrada = reference to procedure(
    const AEntrada: string);

  TCallbacksVistaEntradaStock = record
    AplicarArticulo: TAplicarArticuloEntradaStock;
    MostrarCoincidencias: TMostrarCoincidenciasEntradaStock;
    MostrarTextoNoEncontrado: TMostrarEntradaStockNoEncontrada;
    MostrarCodigoBarrasNoEncontrado: TMostrarEntradaStockNoEncontrada;
  end;

function CrearVistaEntradaStock(
  const ACallbacks: TCallbacksVistaEntradaStock): IVistaEntradaStock;
function CrearRepositorioEntradaStock(
  const ALector: ILectorCatalogosStockConsulta): IRepositorioEntradaStock;

implementation

uses
  System.SysUtils,
  Data.DB;

const
  CAMPO_ARTICULO_PADRE = 'CODIGO_PADRE';
  CAMPO_SKU_COINCIDENCIA = 'CODIGO_SKU';
  CAMPO_DESCRIPCION_COINCIDENCIA = 'DESCRIPCION_ART';
  CAMPO_PROVEEDOR_COINCIDENCIA = 'PROVEEDOR';
  CAMPO_REFERENCIA_COINCIDENCIA = 'REF_PROVEEDOR';

type
  TVistaEntradaStockVcl = class(TInterfacedObject, IVistaEntradaStock)
  private
    FCallbacks: TCallbacksVistaEntradaStock;
  public
    constructor Create(const ACallbacks: TCallbacksVistaEntradaStock);
    procedure AplicarArticulo(
      const ACodigoArticulo, ACodigoSku: string);
    procedure MostrarCoincidencias(
      const ACoincidencias: TCoincidenciasEntradaStock;
      const AEntrada: string);
    procedure MostrarTextoNoEncontrado(const AEntrada: string);
    procedure MostrarCodigoBarrasNoEncontrado(const ACodigo: string);
  end;

  TRepositorioEntradaStockCatalogos = class(
    TInterfacedObject,
    IRepositorioEntradaStock)
  private
    FLector: ILectorCatalogosStockConsulta;
  public
    constructor Create(
      const ALector: ILectorCatalogosStockConsulta);
    function ResolverTexto(
      const AEntrada: string): TCoincidenciasEntradaStock;
  end;

constructor TVistaEntradaStockVcl.Create(
  const ACallbacks: TCallbacksVistaEntradaStock);
begin
  inherited Create;
  FCallbacks := ACallbacks;
end;

procedure TVistaEntradaStockVcl.AplicarArticulo(
  const ACodigoArticulo, ACodigoSku: string);
begin
  FCallbacks.AplicarArticulo(ACodigoArticulo, ACodigoSku);
end;

procedure TVistaEntradaStockVcl.MostrarCoincidencias(
  const ACoincidencias: TCoincidenciasEntradaStock;
  const AEntrada: string);
begin
  FCallbacks.MostrarCoincidencias(ACoincidencias, AEntrada);
end;

procedure TVistaEntradaStockVcl.MostrarTextoNoEncontrado(
  const AEntrada: string);
begin
  FCallbacks.MostrarTextoNoEncontrado(AEntrada);
end;

procedure TVistaEntradaStockVcl.MostrarCodigoBarrasNoEncontrado(
  const ACodigo: string);
begin
  FCallbacks.MostrarCodigoBarrasNoEncontrado(ACodigo);
end;

constructor TRepositorioEntradaStockCatalogos.Create(
  const ALector: ILectorCatalogosStockConsulta);
begin
  inherited Create;
  if not Assigned(ALector) then
    raise EArgumentNilException.Create('ALector');
  FLector := ALector;
end;

// Traduce el dataset del lector de catalogos a coincidencias de dominio,
// para que la aplicacion de entrada no conozca nombres de campo.
function TRepositorioEntradaStockCatalogos.ResolverTexto(
  const AEntrada: string): TCoincidenciasEntradaStock;
var
  Resultado: IResultadoConsultaStock;
  Datos: TDataSet;
  iFila: Integer;
begin
  SetLength(Result, 0);
  Resultado := FLector.ResolverTextoArticulo(AEntrada);
  Datos := Resultado.DataSet;
  if Assigned(Datos) then
  begin
    SetLength(Result, Datos.RecordCount);
    Datos.First;
    iFila := 0;
    while not Datos.Eof do
    begin
      Result[iFila].CodigoArticulo :=
        Datos.FieldByName(CAMPO_ARTICULO_PADRE).AsString;
      Result[iFila].CodigoSku :=
        Datos.FieldByName(CAMPO_SKU_COINCIDENCIA).AsString;
      Result[iFila].Descripcion :=
        Datos.FieldByName(CAMPO_DESCRIPCION_COINCIDENCIA).AsString;
      Result[iFila].Proveedor :=
        Datos.FieldByName(CAMPO_PROVEEDOR_COINCIDENCIA).AsString;
      Result[iFila].ReferenciaProveedor :=
        Datos.FieldByName(CAMPO_REFERENCIA_COINCIDENCIA).AsString;
      Inc(iFila);
      Datos.Next;
    end;
    SetLength(Result, iFila);
  end;
end;

function CrearVistaEntradaStock(
  const ACallbacks: TCallbacksVistaEntradaStock): IVistaEntradaStock;
begin
  Result := TVistaEntradaStockVcl.Create(ACallbacks);
end;

function CrearRepositorioEntradaStock(
  const ALector: ILectorCatalogosStockConsulta): IRepositorioEntradaStock;
begin
  Result := TRepositorioEntradaStockCatalogos.Create(ALector);
end;

end.
