{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataComprasSesionesUnidadTrabajo                           }
{    Tipo:       Repositorio                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Unidad de trabajo UniDAC para materializar sesiones de compra.            }
{******************************************************************************}
unit UniDataComprasSesionesUnidadTrabajo;

interface

uses
  Uni,
  inLibComprasSesionesMaterializacionIntf;

type
  TControlTransaccionMaterializacionUniDAC = class(
    TInterfacedObject,
    IControlTransaccionMaterializacion)
  private
    FConexion: TUniConnection;
  public
    constructor Create(
      AConexion: TUniConnection);
    function EnTransaccion: Boolean;
    procedure IniciarTransaccion;
    procedure ConfirmarTransaccion;
    procedure RevertirTransaccion;
  end;
  TUnidadTrabajoMaterializacionUniDAC = class(
    TInterfacedObject,
    IUnidadTrabajoMaterializacion)
  private
    FControl: IControlTransaccionMaterializacion;
    FIniciada: Boolean;
    FPropietaria: Boolean;
  public
    constructor Create(
      AConexion: TUniConnection); overload;
    constructor Create(
      const AControl: IControlTransaccionMaterializacion); overload;
    procedure Iniciar;
    procedure Confirmar;
    procedure Revertir;
  end;

implementation

uses
  System.SysUtils,
  inLibPrestaShopColaSenal;

resourcestring
  SErrorUnidadTrabajoMaterializacionYaIniciada =
    'La unidad de trabajo ya está iniciada';
  SErrorUnidadTrabajoMaterializacionNoIniciada =
    'La unidad de trabajo no está iniciada';

constructor TControlTransaccionMaterializacionUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TControlTransaccionMaterializacionUniDAC.
  EnTransaccion: Boolean;
begin
  Result := FConexion.InTransaction;
end;

procedure TControlTransaccionMaterializacionUniDAC.
  IniciarTransaccion;
begin
  FConexion.StartTransaction;
end;

procedure TControlTransaccionMaterializacionUniDAC.
  ConfirmarTransaccion;
begin
  FConexion.Commit;
end;

procedure TControlTransaccionMaterializacionUniDAC.
  RevertirTransaccion;
begin
  FConexion.Rollback;
end;

constructor TUnidadTrabajoMaterializacionUniDAC.Create(
  AConexion: TUniConnection);
begin
  Create(
    TControlTransaccionMaterializacionUniDAC.Create(
      AConexion));
end;

constructor TUnidadTrabajoMaterializacionUniDAC.Create(
  const AControl: IControlTransaccionMaterializacion);
begin
  inherited Create;
  if not Assigned(AControl) then
    raise EArgumentNilException.Create('AControl');
  FControl := AControl;
end;

procedure TUnidadTrabajoMaterializacionUniDAC.Iniciar;
begin
  if FIniciada then
    raise EInvalidOpException.Create(
      SErrorUnidadTrabajoMaterializacionYaIniciada);
  FIniciada := True;
  FPropietaria := not FControl.EnTransaccion;
  if FPropietaria then
    FControl.IniciarTransaccion;
end;

procedure TUnidadTrabajoMaterializacionUniDAC.Confirmar;
begin
  if not FIniciada then
    raise EInvalidOpException.Create(
      SErrorUnidadTrabajoMaterializacionNoIniciada);
  if FPropietaria and FControl.EnTransaccion then
  begin
    FControl.ConfirmarTransaccion;
    SolicitarProcesadoPrestaShop;
  end;
  FPropietaria := False;
  FIniciada := False;
end;

procedure TUnidadTrabajoMaterializacionUniDAC.Revertir;
begin
  if FIniciada then
  begin
    if FPropietaria and FControl.EnTransaccion then
      FControl.RevertirTransaccion;
    FPropietaria := False;
    FIniciada := False;
  end;
end;

end.
