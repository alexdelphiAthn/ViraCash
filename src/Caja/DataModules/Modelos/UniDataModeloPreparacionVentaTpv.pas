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
    FReintentarStock: TFunc<string, Boolean>;
    function ComprobarLineas: Boolean;
  public
    // Las líneas son prestadas; solo posee la copia de depósitos apartados.
    constructor Create(ALineas: TDataSet;
      const AValidarStock, AValidarLotes: TProc;
      const AReintentarStock: TFunc<string, Boolean> = nil);
    destructor Destroy; override;
    function LocalizarAtributoPendiente: Integer;
    function ApartarDepositos: Boolean;
    function PrepararLineas: Boolean;
    procedure RestaurarDepositos;
  end;

implementation

uses
  inLibCajaVentaOperacion, inLibCajaVentaIntf, inLibMsgCaja;

constructor TModeloPreparacionVentaTpv.Create(ALineas: TDataSet;
  const AValidarStock, AValidarLotes: TProc;
  const AReintentarStock: TFunc<string, Boolean>);
begin
  inherited Create;
  if ALineas = nil then
    raise EArgumentNilException.Create('ALineas');
  FLineas := ALineas;
  FValidarStock := AValidarStock;
  FValidarLotes := AValidarLotes;
  FReintentarStock := AReintentarStock;
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

function TModeloPreparacionVentaTpv.ComprobarLineas: Boolean;
begin
  try
    CerrarLineaPendiente(FLineas);
    Result := not FLineas.IsEmpty and
      not HayLineasConCantidadCero(FLineas);
    if Result and Assigned(FValidarStock) then
      FValidarStock();
  except
    on E: EStockInsuficienteCaja do
    begin
      // El saldo del artículo por sí solo no identifica la serie agotada.
      if Assigned(FValidarLotes) then
        FValidarLotes();
      raise;
    end;
  end;
  if Result and Assigned(FValidarLotes) then
    FValidarLotes();
end;

function TModeloPreparacionVentaTpv.PrepararLineas: Boolean;
var
  Reintentar: Boolean;
begin
  Result := False;
  repeat
    Reintentar := False;
    try
      Result := ComprobarLineas;
    except
      on E: EStockInsuficienteCaja do
      begin
        if not Assigned(FReintentarStock) then
          raise;
        Reintentar := FReintentarStock(
          MensajeErrorGuardarTicketCaja(E.Message));
      end;
    end;
  until not Reintentar;
end;

procedure TModeloPreparacionVentaTpv.RestaurarDepositos;
begin
  RestaurarDepositosApartadosVenta(FLineas, FApartadas);
end;

end.
