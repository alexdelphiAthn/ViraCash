{******************************************************************************}
{                                                                              }
{  Módulo:       inLibAlbaranesVentaPresentacionMovimientos                   }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Coordina atómicamente los movimientos de salida de un albarán de venta.   }
{******************************************************************************}
unit inLibAlbaranesVentaPresentacionMovimientos;

interface

uses
  System.SysUtils;

type
  TDocumentoMovimientosAlbaranVenta = record
    Serie: string;
    Numero: string;
    Empresa: string;
    Cliente: string;
    Almacen: string;
    Usuario: string;
    TipoDocumento: string;
    TipoMovimiento: string;
    InstanteMovimiento: TDateTime;
    function TieneIdentidad: Boolean;
    function PuedeSincronizar: Boolean;
  end;
  IPersistenciaMovimientosAlbaranVenta = interface
    ['{3D977666-0F0E-48EC-B901-7935EA04AF90}']
    procedure PrepararLineas(
      const ADocumento: TDocumentoMovimientosAlbaranVenta);
    procedure Borrar(
      const ADocumento: TDocumentoMovimientosAlbaranVenta);
    function Generar(
      const ADocumento: TDocumentoMovimientosAlbaranVenta): Integer;
  end;
  IUnidadTrabajoMovimientosAlbaranVenta = interface
    ['{9E42960D-B33E-4081-B89B-EAF7B8D8623A}']
    function EstaActiva: Boolean;
    procedure Iniciar;
    procedure Confirmar;
    procedure Revertir;
  end;
  IOperacionMovimientosAlbaranVenta = interface
    ['{8210DF1F-8661-4473-9D8F-21A4F70B3B79}']
    function Sincronizar(
      const ADocumento: TDocumentoMovimientosAlbaranVenta): Integer;
    function GenerarFaltantes(
      const ADocumento: TDocumentoMovimientosAlbaranVenta): Integer;
  end;

function CrearOperacionMovimientosAlbaranVenta(
  const APersistencia: IPersistenciaMovimientosAlbaranVenta;
  const AUnidadTrabajo: IUnidadTrabajoMovimientosAlbaranVenta):
  IOperacionMovimientosAlbaranVenta;

implementation

type
  TOperacionMovimientosAlbaranVenta = class(
    TInterfacedObject, IOperacionMovimientosAlbaranVenta)
  private
    FPersistencia: IPersistenciaMovimientosAlbaranVenta;
    FUnidadTrabajo: IUnidadTrabajoMovimientosAlbaranVenta;
    function IniciarTransaccionPropia: Boolean;
    procedure ConfirmarTransaccion(AEsPropia: Boolean);
    procedure RevertirTransaccion(AEsPropia: Boolean);
  public
    constructor Create(
      const APersistencia: IPersistenciaMovimientosAlbaranVenta;
      const AUnidadTrabajo: IUnidadTrabajoMovimientosAlbaranVenta);
    function Sincronizar(
      const ADocumento: TDocumentoMovimientosAlbaranVenta): Integer;
    function GenerarFaltantes(
      const ADocumento: TDocumentoMovimientosAlbaranVenta): Integer;
  end;

function TDocumentoMovimientosAlbaranVenta.TieneIdentidad: Boolean;
begin
  Result := (Trim(Serie) <> '') and
            (Trim(Numero) <> '') and
            (Trim(Numero) <> '0');
end;

function TDocumentoMovimientosAlbaranVenta.PuedeSincronizar: Boolean;
begin
  Result := TieneIdentidad and (Trim(Almacen) <> '');
end;

constructor TOperacionMovimientosAlbaranVenta.Create(
  const APersistencia: IPersistenciaMovimientosAlbaranVenta;
  const AUnidadTrabajo: IUnidadTrabajoMovimientosAlbaranVenta);
begin
  inherited Create;
  if APersistencia = nil then
    raise EArgumentNilException.Create('APersistencia');
  if AUnidadTrabajo = nil then
    raise EArgumentNilException.Create('AUnidadTrabajo');
  FPersistencia := APersistencia;
  FUnidadTrabajo := AUnidadTrabajo;
end;

function TOperacionMovimientosAlbaranVenta.IniciarTransaccionPropia:
  Boolean;
begin
  Result := not FUnidadTrabajo.EstaActiva;
  if Result then
    FUnidadTrabajo.Iniciar;
end;

procedure TOperacionMovimientosAlbaranVenta.ConfirmarTransaccion(
  AEsPropia: Boolean);
begin
  if AEsPropia then
    FUnidadTrabajo.Confirmar;
end;

procedure TOperacionMovimientosAlbaranVenta.RevertirTransaccion(
  AEsPropia: Boolean);
begin
  if AEsPropia and FUnidadTrabajo.EstaActiva then
    FUnidadTrabajo.Revertir;
end;

function TOperacionMovimientosAlbaranVenta.Sincronizar(
  const ADocumento: TDocumentoMovimientosAlbaranVenta): Integer;
var
  EsTransaccionPropia: Boolean;
begin
  Result := 0;
  if ADocumento.PuedeSincronizar then
  begin
    EsTransaccionPropia := IniciarTransaccionPropia;
    try
      FPersistencia.PrepararLineas(ADocumento);
      FPersistencia.Borrar(ADocumento);
      Result := FPersistencia.Generar(ADocumento);
      ConfirmarTransaccion(EsTransaccionPropia);
    except
      RevertirTransaccion(EsTransaccionPropia);
      raise;
    end;
  end;
end;

function TOperacionMovimientosAlbaranVenta.GenerarFaltantes(
  const ADocumento: TDocumentoMovimientosAlbaranVenta): Integer;
var
  EsTransaccionPropia: Boolean;
begin
  Result := 0;
  if ADocumento.TieneIdentidad then
  begin
    EsTransaccionPropia := IniciarTransaccionPropia;
    try
      Result := FPersistencia.Generar(ADocumento);
      ConfirmarTransaccion(EsTransaccionPropia);
    except
      RevertirTransaccion(EsTransaccionPropia);
      raise;
    end;
  end;
end;

function CrearOperacionMovimientosAlbaranVenta(
  const APersistencia: IPersistenciaMovimientosAlbaranVenta;
  const AUnidadTrabajo: IUnidadTrabajoMovimientosAlbaranVenta):
  IOperacionMovimientosAlbaranVenta;
begin
  Result := TOperacionMovimientosAlbaranVenta.Create(
    APersistencia, AUnidadTrabajo);
end;

end.
