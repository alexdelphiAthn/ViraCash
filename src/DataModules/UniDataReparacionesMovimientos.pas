{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataReparacionesMovimientos                                }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Seguimiento de reparaciones y conservación de evidencias.                 }
{******************************************************************************}
unit UniDataReparacionesMovimientos;

interface

uses
  System.Classes, Data.DB, Uni, inLibReparacionesMovimientos;

type
  TDatosMovimientosReparacion = class(TComponent)
  private
    FConexion: TUniConnection;
    FConsulta: TUniQuery;
    FOrigen: TDataSource;
    procedure ComprobarAnterior(const AMovimiento: TMovimientoReparacion);
  public
    constructor CreateDatos(AOwner: TComponent; AConexion: TUniConnection);
    procedure AsignarMaestro(AMaestro: TDataSource);
    procedure Refrescar;
    procedure Registrar(const AMovimiento: TMovimientoReparacion);
    function Actual: TMovimientoReparacion;
    property Origen: TDataSource read FOrigen;
  end;

implementation

uses
  System.SysUtils, inLibMsgReparaciones;

constructor TDatosMovimientosReparacion.CreateDatos(AOwner: TComponent;
  AConexion: TUniConnection);
begin
  inherited Create(AOwner);
  FConexion := AConexion;
  FConsulta := TUniQuery.Create(Self);
  FConsulta.Connection := FConexion;
  FConsulta.ReadOnly := True;
  FConsulta.SQL.Text :=
    'SELECT ID_GARMOV, ID_GAR_GARMOV, ID_ANTERIOR_GARMOV, ' +
    'INSTANTE_GARMOV, ORIGEN_GARMOV, DESTINO_GARMOV, ESTADO_GARMOV, ' +
    'OBJETO_GARMOV, AGENCIA_GARMOV, TRACKING_GARMOV, INCIDENCIA_GARMOV, ' +
    'USUARIO_ALTA, INSTANTE_ALTA FROM fza_garantias_movimientos ' +
    'WHERE ID_GAR_GARMOV = :ID_GAR ' +
    'ORDER BY INSTANTE_GARMOV, ID_GARMOV';
  FOrigen := TDataSource.Create(Self);
  FOrigen.DataSet := FConsulta;
end;

procedure TDatosMovimientosReparacion.AsignarMaestro(AMaestro: TDataSource);
begin
  FConsulta.MasterSource := AMaestro;
  FConsulta.MasterFields := 'ID_GAR';
  FConsulta.DetailFields := 'ID_GAR_GARMOV';
  FConsulta.Open;
end;

procedure TDatosMovimientosReparacion.Refrescar;
begin
  if FConsulta.Active then
    FConsulta.Refresh;
end;

function TDatosMovimientosReparacion.Actual: TMovimientoReparacion;
begin
  Result := Default(TMovimientoReparacion);
  if FConsulta.Active and not FConsulta.IsEmpty then
  begin
    Result.Anterior := FConsulta.FieldByName('ID_GARMOV').AsLargeInt;
    Result.Reparacion := FConsulta.FieldByName('ID_GAR_GARMOV').AsLargeInt;
    Result.Origen := FConsulta.FieldByName('ORIGEN_GARMOV').AsString;
    Result.Destino := FConsulta.FieldByName('DESTINO_GARMOV').AsString;
    Result.Objeto := FConsulta.FieldByName('OBJETO_GARMOV').AsString;
    Result.Agencia := FConsulta.FieldByName('AGENCIA_GARMOV').AsString;
    Result.Seguimiento := FConsulta.FieldByName('TRACKING_GARMOV').AsString;
  end;
end;

procedure TDatosMovimientosReparacion.ComprobarAnterior(
  const AMovimiento: TMovimientoReparacion);
var
  oConsulta: TUniQuery;
begin
  if AMovimiento.Anterior > 0 then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text := 'SELECT ID_GARMOV ' +
        'FROM fza_garantias_movimientos WHERE ID_GARMOV = :ANTERIOR ' +
        'AND ID_GAR_GARMOV = :REPARACION';
      oConsulta.ParamByName('ANTERIOR').AsLargeInt := AMovimiento.Anterior;
      oConsulta.ParamByName('REPARACION').AsLargeInt :=
        AMovimiento.Reparacion;
      oConsulta.Open;
      if oConsulta.IsEmpty then
        raise EArgumentException.Create(SMovimientoAnteriorInvalido);
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

procedure TDatosMovimientosReparacion.Registrar(
  const AMovimiento: TMovimientoReparacion);
var
  oConsulta: TUniQuery;
  sError: string;
begin
  sError := ValidarMovimientoReparacion(AMovimiento);
  if sError <> '' then
    raise EArgumentException.Create(sError);
  ComprobarAnterior(AMovimiento);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := 'INSERT INTO fza_garantias_movimientos ' +
      '(ID_GAR_GARMOV, ID_ANTERIOR_GARMOV, INSTANTE_GARMOV, ' +
      'ORIGEN_GARMOV, DESTINO_GARMOV, ESTADO_GARMOV, OBJETO_GARMOV, ' +
      'AGENCIA_GARMOV, TRACKING_GARMOV, INCIDENCIA_GARMOV, ' +
      'INSTANTE_ALTA, USUARIO_ALTA) ' +
      'SELECT G.ID_GAR, NULLIF(:ANTERIOR, 0), :INSTANTE, ' +
      ':ORIGEN, :DESTINO, :ESTADO, :OBJETO, :AGENCIA, :TRACKING, ' +
      ':INCIDENCIA, NOW(), :USUARIO FROM fza_garantias_reclamaciones G ' +
      'WHERE G.ID_GAR = :REPARACION';
    oConsulta.ParamByName('REPARACION').AsLargeInt := AMovimiento.Reparacion;
    oConsulta.ParamByName('ANTERIOR').AsLargeInt := AMovimiento.Anterior;
    oConsulta.ParamByName('INSTANTE').AsDateTime := AMovimiento.Instante;
    oConsulta.ParamByName('ORIGEN').AsString := Trim(AMovimiento.Origen);
    oConsulta.ParamByName('DESTINO').AsString := Trim(AMovimiento.Destino);
    oConsulta.ParamByName('ESTADO').AsString := AMovimiento.Estado;
    oConsulta.ParamByName('OBJETO').AsString := Trim(AMovimiento.Objeto);
    oConsulta.ParamByName('AGENCIA').AsString := Trim(AMovimiento.Agencia);
    oConsulta.ParamByName('TRACKING').AsString := Trim(AMovimiento.Seguimiento);
    oConsulta.ParamByName('INCIDENCIA').AsString :=
      Trim(AMovimiento.Incidencia);
    oConsulta.ParamByName('USUARIO').AsString := AMovimiento.Usuario;
    oConsulta.Execute;
    if oConsulta.RowsAffected <> 1 then
      raise EArgumentException.Create(SInfoSinReparacion);
  finally
    FreeAndNil(oConsulta);
  end;
  Refrescar;
end;

end.
