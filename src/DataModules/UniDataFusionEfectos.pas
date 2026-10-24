{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFusionEfectos                                         }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adapta los data modules UniDAC al repositorio de fusión de efectos.       }
{******************************************************************************}
unit UniDataFusionEfectos;

interface

uses
  UniDataEfectosCompra,
  UniDataEfectosVenta,
  inLibFusionEfectosIntf;

function CrearRepositorioFusionEfectosCompraUniDAC(
  ADataModule: TdmEfectosCompra): IRepositorioFusionEfectos;
function CrearRepositorioFusionEfectosVentaUniDAC(
  ADataModule: TdmEfectosVenta): IRepositorioFusionEfectos;

implementation

uses
  System.SysUtils;

type
  TRepositorioFusionEfectosCompraUniDAC = class(
    TInterfacedObject,
    IRepositorioFusionEfectos)
  private
    FDataModule: TdmEfectosCompra;
  public
    constructor Create(ADataModule: TdmEfectosCompra);
    function Fusionar(
      const AClaves: TClavesFusionEfectos
    ): TResultadoFusionEfectos;
  end;
  TRepositorioFusionEfectosVentaUniDAC = class(
    TInterfacedObject,
    IRepositorioFusionEfectos)
  private
    FDataModule: TdmEfectosVenta;
  public
    constructor Create(ADataModule: TdmEfectosVenta);
    function Fusionar(
      const AClaves: TClavesFusionEfectos
    ): TResultadoFusionEfectos;
  end;

constructor TRepositorioFusionEfectosCompraUniDAC.Create(
  ADataModule: TdmEfectosCompra);
begin
  inherited Create;
  if not Assigned(ADataModule) then
    raise EArgumentNilException.Create('ADataModule');
  FDataModule := ADataModule;
end;

function TRepositorioFusionEfectosCompraUniDAC.Fusionar(
  const AClaves: TClavesFusionEfectos
): TResultadoFusionEfectos;
var
  aClavesCompra: TClavesEfectoCompra;
  i: Integer;
begin
  SetLength(aClavesCompra, Length(AClaves));
  for i := 0 to Length(AClaves) - 1 do
  begin
    aClavesCompra[i].SerieFac := AClaves[i].SerieFactura;
    aClavesCompra[i].NumeroFac := AClaves[i].NumeroFactura;
    aClavesCompra[i].NumeroEfec := AClaves[i].NumeroEfecto;
  end;
  Result := Default(TResultadoFusionEfectos);
  Result.Cantidad := FDataModule.FusionarEfectosPendientes(
    aClavesCompra,
    Result.Referencia);
end;

constructor TRepositorioFusionEfectosVentaUniDAC.Create(
  ADataModule: TdmEfectosVenta);
begin
  inherited Create;
  if not Assigned(ADataModule) then
    raise EArgumentNilException.Create('ADataModule');
  FDataModule := ADataModule;
end;

function TRepositorioFusionEfectosVentaUniDAC.Fusionar(
  const AClaves: TClavesFusionEfectos
): TResultadoFusionEfectos;
var
  aClavesVenta: TClavesEfectoVenta;
  i: Integer;
begin
  SetLength(aClavesVenta, Length(AClaves));
  for i := 0 to Length(AClaves) - 1 do
  begin
    aClavesVenta[i].SerieFac := AClaves[i].SerieFactura;
    aClavesVenta[i].NumeroFac := AClaves[i].NumeroFactura;
    aClavesVenta[i].NumeroEfec := AClaves[i].NumeroEfecto;
  end;
  Result := Default(TResultadoFusionEfectos);
  Result.Cantidad := FDataModule.FusionarEfectosPendientes(
    aClavesVenta,
    Result.Referencia);
end;

function CrearRepositorioFusionEfectosCompraUniDAC(
  ADataModule: TdmEfectosCompra): IRepositorioFusionEfectos;
begin
  Result := TRepositorioFusionEfectosCompraUniDAC.Create(ADataModule);
end;

function CrearRepositorioFusionEfectosVentaUniDAC(
  ADataModule: TdmEfectosVenta): IRepositorioFusionEfectos;
begin
  Result := TRepositorioFusionEfectosVentaUniDAC.Create(ADataModule);
end;

end.
