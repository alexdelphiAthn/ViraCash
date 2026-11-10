{******************************************************************************}
{                                                                              }
{  Módulo: UniDataMeteorologiaCaja                                             }
{  Tipo: Librería                                                              }
{  Versión: 1.0.0                                                              }
{  Fecha: 12/11/2026                                                           }
{  Autor: Alejandro Laorden Hidalgo                                            }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción: Persistencia de los partes meteorológicos del almacén.         }
{******************************************************************************}
unit UniDataMeteorologiaCaja;

interface

uses
  Uni, inLibMeteorologiaCajaIntf;

function CrearRepositorioMeteorologiaCaja(AConexion: TUniConnection):
  IRepositorioMeteorologiaCaja;

implementation

uses
  System.SysUtils, Data.DB, DBAccess, inLibMsgMeteorologiaCaja;

type
  TRepositorioMeteorologiaCaja = class(TInterfacedObject,
    IRepositorioMeteorologiaCaja, IRepositorioObservacionesCaja)
  private
    FConexion: TUniConnection;
    procedure AsignarValor(AConsulta: TUniQuery; const ANombre: string;
      const AValor: TValorMeteorologiaCaja);
  public
    function LeerObservaciones(const AEmpresa, AAlmacen: string;
      AFecha: TDateTime): string;
    procedure GuardarObservaciones(const AEmpresa, AAlmacen: string;
      AFecha: TDateTime; const ATexto, AUsuario: string);
    constructor Create(AConexion: TUniConnection);
    function LeerUbicacion(const AEmpresa, AAlmacen: string):
      TUbicacionMeteorologiaCaja;
    procedure Guardar(const AUbicacion: TUbicacionMeteorologiaCaja;
      const AParte: TParteMeteorologiaCaja);
  end;

constructor TRepositorioMeteorologiaCaja.Create(AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function CrearRepositorioMeteorologiaCaja(AConexion: TUniConnection):
  IRepositorioMeteorologiaCaja;
begin
  Result := TRepositorioMeteorologiaCaja.Create(AConexion);
end;

function TRepositorioMeteorologiaCaja.LeerUbicacion(
  const AEmpresa, AAlmacen: string): TUbicacionMeteorologiaCaja;
var
  oConsulta: TUniQuery;
begin
  Result := Default(TUbicacionMeteorologiaCaja);
  Result.Empresa := AEmpresa;
  Result.Almacen := AAlmacen;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT POBLACION_ALM, CODIGO_POSTAL_ALM FROM fza_almacenes' +
      ' WHERE CODIGO_ALM_ALM = :ALMACEN';
    oConsulta.ParamByName('ALMACEN').AsString := AAlmacen;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      Result.Ciudad := Trim(
        oConsulta.FieldByName('POBLACION_ALM').AsString);
      Result.CodigoPostal := Trim(
        oConsulta.FieldByName('CODIGO_POSTAL_ALM').AsString);
    end;
    if Result.Ciudad = '' then
      raise EInvalidOpException.Create(SErrorCiudadMeteoCaja);

  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioMeteorologiaCaja.AsignarValor(AConsulta: TUniQuery;
  const ANombre: string; const AValor: TValorMeteorologiaCaja);
begin
  AConsulta.ParamByName(ANombre).DataType := ftFloat;
  if AValor.TieneValor then
    AConsulta.ParamByName(ANombre).AsFloat := AValor.Valor
  else
    AConsulta.ParamByName(ANombre).Clear;
end;

procedure ComprobarEsquemaMeteorologia(AConsulta: TUniQuery);
begin
    AConsulta.Close;
    AConsulta.SQL.Text :=
      'SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES' +
      ' WHERE TABLE_SCHEMA = DATABASE()' +
      ' AND TABLE_NAME = ''fza_almacenes_meteorologia''';
    AConsulta.Open;
    if AConsulta.Fields[0].AsInteger <> 1 then
      raise EInvalidOpException.Create(SErrorEsquemaMeteoCaja);
  AConsulta.Close;
end;

function SqlGuardarParteMeteorologiaCaja: string;
begin
  Result :=
      'INSERT INTO fza_almacenes_meteorologia (' +
      ' CODIGO_EMP_ALMET, CODIGO_ALM_ALMET, FECHA_ALMET,' +
      ' CIUDAD_ALMET, ZONA_HORARIA_ALMET, VALOR_LATITUD_ALMET,' +
      ' VALOR_LONGITUD_ALMET, VALOR_TEMPERATURA_ALMET,' +
      ' VALOR_MINIMA_ALMET, VALOR_MAXIMA_ALMET, PORCENTAJE_NUBES_ALMET,' +
      ' VALOR_LLUVIA_PREVISTA_ALMET, CODIGO_TIEMPO_ALMET,' +
      ' INSTANTE_CONSULTA_UTC_ALMET, PROVEEDOR_ALMET, RESPUESTA_JSON_ALMET)' +
      ' VALUES (:EMPRESA, :ALMACEN, :FECHA, :CIUDAD, :ZONA,' +
      ' :LATITUD, :LONGITUD, :TEMPERATURA, :MINIMA, :MAXIMA, :NUBES,' +
      ' :LLUVIA, :CODIGO, :CONSULTA, ''Open-Meteo'', :JSON)' +
      ' ON DUPLICATE KEY UPDATE CIUDAD_ALMET = VALUES(CIUDAD_ALMET),' +
      ' ZONA_HORARIA_ALMET = VALUES(ZONA_HORARIA_ALMET),' +
      ' VALOR_LATITUD_ALMET = VALUES(VALOR_LATITUD_ALMET),' +
      ' VALOR_LONGITUD_ALMET = VALUES(VALOR_LONGITUD_ALMET),' +
      ' VALOR_TEMPERATURA_ALMET = VALUES(VALOR_TEMPERATURA_ALMET),' +
      ' VALOR_MINIMA_ALMET = VALUES(VALOR_MINIMA_ALMET),' +
      ' VALOR_MAXIMA_ALMET = VALUES(VALOR_MAXIMA_ALMET),' +
      ' PORCENTAJE_NUBES_ALMET = VALUES(PORCENTAJE_NUBES_ALMET),' +
      ' VALOR_LLUVIA_PREVISTA_ALMET = VALUES(VALOR_LLUVIA_PREVISTA_ALMET),' +
      ' CODIGO_TIEMPO_ALMET = VALUES(CODIGO_TIEMPO_ALMET),' +
      ' INSTANTE_CONSULTA_UTC_ALMET = VALUES(INSTANTE_CONSULTA_UTC_ALMET),' +
      ' PROVEEDOR_ALMET = VALUES(PROVEEDOR_ALMET),' +
      ' RESPUESTA_JSON_ALMET = VALUES(RESPUESTA_JSON_ALMET)';
end;

procedure TRepositorioMeteorologiaCaja.Guardar(
  const AUbicacion: TUbicacionMeteorologiaCaja;
  const AParte: TParteMeteorologiaCaja);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    ComprobarEsquemaMeteorologia(oConsulta);
    oConsulta.SQL.Text := SqlGuardarParteMeteorologiaCaja;
    oConsulta.ParamByName('EMPRESA').AsString := AUbicacion.Empresa;
    oConsulta.ParamByName('ALMACEN').AsString := AUbicacion.Almacen;
    oConsulta.ParamByName('FECHA').AsDate := AParte.Fecha;
    oConsulta.ParamByName('CIUDAD').AsString := AParte.Ciudad;
    oConsulta.ParamByName('ZONA').AsString := AParte.ZonaHoraria;
    oConsulta.ParamByName('LATITUD').AsFloat := AParte.Latitud;
    oConsulta.ParamByName('LONGITUD').AsFloat := AParte.Longitud;
    oConsulta.ParamByName('CONSULTA').AsDateTime := AParte.InstanteConsultaUtc;
    oConsulta.ParamByName('JSON').AsMemo := AParte.RespuestaJson;
    AsignarValor(oConsulta, 'TEMPERATURA', AParte.Temperatura);
    AsignarValor(oConsulta, 'MINIMA', AParte.Minima);
    AsignarValor(oConsulta, 'MAXIMA', AParte.Maxima);
    AsignarValor(oConsulta, 'NUBES', AParte.Nubes);
    AsignarValor(oConsulta, 'LLUVIA', AParte.Lluvia);
    AsignarValor(oConsulta, 'CODIGO', AParte.CodigoTiempo);
    oConsulta.ExecSQL;
  finally
    FreeAndNil(oConsulta);
  end;
end;


procedure PrepararConsultaObservaciones(AConsulta: TUniQuery;
  const AEmpresa, AAlmacen: string; AFecha: TDateTime);
begin
  if (Trim(AEmpresa) = '') or (Trim(AAlmacen) = '') or (AFecha <= 0) then
    raise EArgumentException.Create(SErrorUbicacionObservacionesCaja);
  AConsulta.SQL.Text :=
    'SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES' +
    ' WHERE TABLE_SCHEMA = DATABASE()' +
    ' AND TABLE_NAME = ''fza_almacenes_observaciones''';
  AConsulta.Open;
  if AConsulta.Fields[0].AsInteger <> 1 then
    raise EInvalidOpException.Create(SErrorEsquemaObservacionesCaja);
  AConsulta.Close;
end;

function TRepositorioMeteorologiaCaja.LeerObservaciones(
  const AEmpresa, AAlmacen: string; AFecha: TDateTime): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    PrepararConsultaObservaciones(oConsulta, AEmpresa, AAlmacen, AFecha);
    oConsulta.SQL.Text :=
      'SELECT OBSERVACIONES_ALOB FROM fza_almacenes_observaciones' +
      ' WHERE CODIGO_EMP_ALOB = :EMPRESA AND CODIGO_ALM_ALOB = :ALMACEN' +
      ' AND FECHA_ALOB = :FECHA';
    oConsulta.ParamByName('EMPRESA').AsString := AEmpresa;
    oConsulta.ParamByName('ALMACEN').AsString := AAlmacen;
    oConsulta.ParamByName('FECHA').AsDate := Trunc(AFecha);
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      Result := oConsulta.Fields[0].AsString;
  finally
    oConsulta.Free;
  end;
end;

procedure TRepositorioMeteorologiaCaja.GuardarObservaciones(
  const AEmpresa, AAlmacen: string; AFecha: TDateTime;
  const ATexto, AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  if Length(ATexto) > 4000 then
    raise EArgumentException.Create(SErrorLongitudObservacionesCaja);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    PrepararConsultaObservaciones(oConsulta, AEmpresa, AAlmacen, AFecha);
    oConsulta.SQL.Text :=
      'INSERT INTO fza_almacenes_observaciones (' +
      ' CODIGO_EMP_ALOB, CODIGO_ALM_ALOB, FECHA_ALOB, OBSERVACIONES_ALOB,' +
      ' INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF)' +
      ' VALUES (:EMPRESA, :ALMACEN, :FECHA, :TEXTO,' +
      ' CURRENT_TIMESTAMP, :USUARIO, CURRENT_TIMESTAMP, :USUARIO)' +
      ' ON DUPLICATE KEY UPDATE' +
      ' OBSERVACIONES_ALOB = VALUES(OBSERVACIONES_ALOB),' +
      ' INSTANTE_MODIF = CURRENT_TIMESTAMP,' +
      ' USUARIO_MODIF = VALUES(USUARIO_MODIF)';
    oConsulta.ParamByName('EMPRESA').AsString := AEmpresa;
    oConsulta.ParamByName('ALMACEN').AsString := AAlmacen;
    oConsulta.ParamByName('FECHA').AsDate := Trunc(AFecha);
    oConsulta.ParamByName('TEXTO').AsMemo := ATexto;
    oConsulta.ParamByName('USUARIO').AsString := AUsuario;
    oConsulta.ExecSQL;
  finally
    oConsulta.Free;
  end;
end;

end.
