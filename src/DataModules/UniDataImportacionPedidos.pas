{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataImportacionPedidos                                    }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adapta el data module UniDAC al repositorio de importación.               }
{******************************************************************************}
unit UniDataImportacionPedidos;

interface

uses
  UniDataPedidos,
  inLibImportacionPedidosIntf;

function CrearRepositorioImportacionPedidosUniDAC(
  ADataModule: TdmPedidos): IRepositorioImportacionPedidos;

implementation

uses
  System.SysUtils,
  inLibPresta;

type
  TRepositorioImportacionPedidosUniDAC = class(
    TInterfacedObject,
    IRepositorioImportacionPedidos)
  private
    FDataModule: TdmPedidos;
  public
    constructor Create(ADataModule: TdmPedidos);
    function Existe(const AOrigen, AIdPedido: string): Boolean;
    function UltimoIdImportado(const AOrigen: string): Int64;
    function Importar(
      const AOrigen: string;
      APedido: TOrder): Boolean;
  end;

constructor TRepositorioImportacionPedidosUniDAC.Create(
  ADataModule: TdmPedidos);
begin
  inherited Create;
  if not Assigned(ADataModule) then
    raise EArgumentNilException.Create('ADataModule');
  FDataModule := ADataModule;
end;

function TRepositorioImportacionPedidosUniDAC.Existe(
  const AOrigen, AIdPedido: string): Boolean;
begin
  Result := FDataModule.ExistePedidoPrestaShop(AOrigen, AIdPedido);
end;

function TRepositorioImportacionPedidosUniDAC.UltimoIdImportado(
  const AOrigen: string): Int64;
begin
  Result := FDataModule.UltimoIdPedidoPrestaShop(AOrigen);
end;

function TRepositorioImportacionPedidosUniDAC.Importar(
  const AOrigen: string;
  APedido: TOrder): Boolean;
begin
  Result := FDataModule.ImportarPedidoPrestaShop(APedido, AOrigen);
end;

function CrearRepositorioImportacionPedidosUniDAC(
  ADataModule: TdmPedidos): IRepositorioImportacionPedidos;
begin
  Result := TRepositorioImportacionPedidosUniDAC.Create(ADataModule);
end;

end.
