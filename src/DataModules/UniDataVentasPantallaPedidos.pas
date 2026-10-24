{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataVentasPantallaPedidos                                  }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Adapta la creacion transaccional de albaranes del modulo de pedidos al    }
{    puerto estrecho que consume el caso de uso de ventas.                     }
{******************************************************************************}
unit UniDataVentasPantallaPedidos;

interface

uses
  UniDataPedidos,
  inLibVentasPantallaCrearAlbaran;

function CrearRepositorioCreacionAlbaranPedidoUniDAC(
  ADataModule: TdmPedidos): IRepositorioCreacionAlbaranPedido;

implementation

uses
  System.SysUtils,
  System.Generics.Collections;

type
  TRepositorioCreacionAlbaranPedidoUniDAC = class(
    TInterfacedObject,
    IRepositorioCreacionAlbaranPedido)
  private
    FDataModule: TdmPedidos;
  public
    constructor Create(ADataModule: TdmPedidos);
    function Crear(
      const ASolicitud: TSolicitudCreacionAlbaranPedido):
      TResultadoCreacionAlbaranPedido;
  end;

constructor TRepositorioCreacionAlbaranPedidoUniDAC.Create(
  ADataModule: TdmPedidos);
begin
  inherited Create;
  if not Assigned(ADataModule) then
    raise EArgumentNilException.Create('ADataModule');
  FDataModule := ADataModule;
end;

function TRepositorioCreacionAlbaranPedidoUniDAC.Crear(
  const ASolicitud: TSolicitudCreacionAlbaranPedido):
  TResultadoCreacionAlbaranPedido;
var
  iEntrega: Integer;
  oEntregas: TList<TPair<string, Currency>>;
  oPar: TPair<string, Currency>;
begin
  Result := Default(TResultadoCreacionAlbaranPedido);
  oEntregas := TList<TPair<string, Currency>>.Create;
  try
    for iEntrega := 0 to High(ASolicitud.Entregas) do
    begin
      oPar.Key := ASolicitud.Entregas[iEntrega].Linea;
      oPar.Value :=
        ASolicitud.Entregas[iEntrega].CantidadTotalEntregada;
      oEntregas.Add(oPar);
    end;
    Result.Creado := FDataModule.CrearAlbaranDesdePedido(
      Result.Numero,
      Result.Serie,
      oEntregas,
      ASolicitud.CodigoAlmacen,
      ASolicitud.NumeroAlbaranExistente,
      ASolicitud.SerieAlbaranExistente,
      ASolicitud.AlbaranNuevo);
  finally
    FreeAndNil(oEntregas);
  end;
end;

function CrearRepositorioCreacionAlbaranPedidoUniDAC(
  ADataModule: TdmPedidos): IRepositorioCreacionAlbaranPedido;
begin
  Result := TRepositorioCreacionAlbaranPedidoUniDAC.Create(ADataModule);
end;

end.
