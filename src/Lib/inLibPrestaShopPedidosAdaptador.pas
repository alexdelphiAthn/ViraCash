{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPrestaShopPedidosAdaptador                              }
{    Tipo:       Adaptador REST                                                }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adapta la API REST de PrestaShop a la fuente de pedidos.                  }
{******************************************************************************}
unit inLibPrestaShopPedidosAdaptador;

interface

uses
  inLibImportacionPedidosIntf, inLibLogIntf;

function CrearFabricaFuentePedidosPrestaShop(
  const ARegistroLog: IRegistroLog):
  IFabricaFuentePedidosImportacion;

implementation

uses
  System.SysUtils,
  inLibPresta,
  inLibPrestaImporter;

type
  TFuentePedidosPrestaShop = class(
    TInterfacedObject,
    IFuentePedidosImportacion)
  private
    FBaseURL: string;
    FApiKey: string;
    FConexion: TPrestaConn;
    FRegistroLog: IRegistroLog;
  public
    constructor Create(const ABaseURL, AApiKey: string;
      const ARegistroLog: IRegistroLog);
    destructor Destroy; override;
    function ListarResumen(
      AIdDesde: Int64;
      ALista: TResumenPedidosImportacion): Boolean;
    function CargarPedido(const AIdPedido: string): TOrder;
  end;
  TFabricaFuentePedidosPrestaShop = class(
    TInterfacedObject,
    IFabricaFuentePedidosImportacion)
  private
    FRegistroLog: IRegistroLog;
  public
    constructor Create(const ARegistroLog: IRegistroLog);
    function Crear(
      const ABaseURL, AApiKey: string): IFuentePedidosImportacion;
  end;

constructor TFuentePedidosPrestaShop.Create(
  const ABaseURL, AApiKey: string;
  const ARegistroLog: IRegistroLog);
begin
  inherited Create;
  FBaseURL := ABaseURL;
  FApiKey := AApiKey;
  FRegistroLog := ARegistroLog;
  FConexion := TPrestaConn.Create(ABaseURL, AApiKey, FRegistroLog);
end;

destructor TFuentePedidosPrestaShop.Destroy;
begin
  FreeAndNil(FConexion);
  inherited;
end;

function TFuentePedidosPrestaShop.ListarResumen(
  AIdDesde: Int64;
  ALista: TResumenPedidosImportacion): Boolean;
var
  i: Integer;
  oListaPresta: TPrestaPedidoResumenList;
  oResumen: TResumenPedidoImportacion;
begin
  oListaPresta := TPrestaPedidoResumenList.Create;
  try
    Result := FConexion.ListarPedidosResumen(AIdDesde, oListaPresta);
    if Result then
    begin
      ALista.Clear;
      for i := 0 to oListaPresta.Count - 1 do
      begin
        oResumen := Default(TResumenPedidoImportacion);
        oResumen.IdPedido := oListaPresta[i].IdPedido;
        oResumen.Referencia := oListaPresta[i].Referencia;
        oResumen.Fecha := oListaPresta[i].Fecha;
        oResumen.Cliente := oListaPresta[i].Cliente;
        oResumen.Total := oListaPresta[i].Total;
        oResumen.Estado := oListaPresta[i].Estado;
        ALista.Add(oResumen);
      end;
    end;
  finally
    FreeAndNil(oListaPresta);
  end;
end;

function TFuentePedidosPrestaShop.CargarPedido(
  const AIdPedido: string): TOrder;
begin
  Result := FConexion.CargarPedido(AIdPedido);
end;

constructor TFabricaFuentePedidosPrestaShop.Create(
  const ARegistroLog: IRegistroLog);
begin
  inherited Create;
  FRegistroLog := ARegistroLog;
end;

function TFabricaFuentePedidosPrestaShop.Crear(
  const ABaseURL, AApiKey: string): IFuentePedidosImportacion;
begin
  Result := TFuentePedidosPrestaShop.Create(
    ABaseURL, AApiKey, FRegistroLog);
end;

function CrearFabricaFuentePedidosPrestaShop(
  const ARegistroLog: IRegistroLog):
  IFabricaFuentePedidosImportacion;
begin
  Result := TFabricaFuentePedidosPrestaShop.Create(ARegistroLog);
end;

end.
