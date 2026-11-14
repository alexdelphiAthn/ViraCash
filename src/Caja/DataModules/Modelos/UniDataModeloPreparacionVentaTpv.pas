{******************************************************************************}
{                                                                              }
{  Módulo: UniDataModeloPreparacionVentaTpv                                    }
{  Tipo: Librería                                                              }
{  Versión: 1.0.0                                                              }
{  Fecha: 14/11/2026                                                           }
{  Autor: Alejandro Laorden Hidalgo                                            }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción: Adapta las líneas y depósitos al cierre del TPV.               }
{                                                                              }
{******************************************************************************}

unit UniDataModeloPreparacionVentaTpv;

interface

uses
  System.SysUtils, Data.DB, Datasnap.DBClient,
  inLibTpvMvcIntf;

type
  TModeloPreparacionVentaTpv = class(TInterfacedObject,
    IModeloPreparacionVentaTpv)
  private
    FLineas: TDataSet;
    FApartadas: TClientDataSet;
    FValidarStock: TProc;
    FValidarLotes: TProc;
  public
    // Las líneas son prestadas; solo posee la copia de depósitos apartados.
    constructor Create(ALineas: TDataSet;
      const AValidarStock, AValidarLotes: TProc);
    destructor Destroy; override;
    function LocalizarAtributoPendiente: Integer;
    function ApartarDepositos: Boolean;
    function PrepararLineas: Boolean;
    procedure RestaurarDepositos;
  end;

implementation

uses
  inLibCajaVentaOperacion;

constructor TModeloPreparacionVentaTpv.Create(ALineas: TDataSet;
  const AValidarStock, AValidarLotes: TProc);
begin
  inherited Create;
  if ALineas = nil then
    raise EArgumentNilException.Create('ALineas');
  FLineas := ALineas;
  FValidarStock := AValidarStock;
  FValidarLotes := AValidarLotes;
  FApartadas := TClientDataSet.Create(nil);
end;

destructor TModeloPreparacionVentaTpv.Destroy;
begin
  FreeAndNil(FApartadas);
  inherited;
end;

function TModeloPreparacionVentaTpv.LocalizarAtributoPendiente: Integer;
begin
  Result := LocalizarLineaConAtributosPendientesCaja(FLineas);
end;

function TModeloPreparacionVentaTpv.ApartarDepositos: Boolean;
begin
  Result := (ApartarDepositosNoMarcadosVenta(FLineas, FApartadas) = 0) or
    not OperacionVentaVacia(FLineas);
end;

function TModeloPreparacionVentaTpv.PrepararLineas: Boolean;
begin
  CerrarLineaPendiente(FLineas);
  Result := not FLineas.IsEmpty and
    not HayLineasConCantidadCero(FLineas);
  if Result then
  begin
    if Assigned(FValidarStock) then
      FValidarStock();
    if Assigned(FValidarLotes) then
      FValidarLotes();
  end;
end;

procedure TModeloPreparacionVentaTpv.RestaurarDepositos;
begin
  RestaurarDepositosApartadosVenta(FLineas, FApartadas);
end;

end.
