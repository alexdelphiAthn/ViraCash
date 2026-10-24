{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataCajaPantallaHistoricos                                }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Adapta la transacción UniDAC usada al guardar perfiles de históricos.    }
{******************************************************************************}
unit UniDataCajaPantallaHistoricos;

interface

uses
  inLibConexionesIntf,
  inLibContextoSesionIntf,
  inLibPerfilesUsuarioIntf,
  inLibCajaPantallaHistoricosIntf;

function CrearGrabadorPerfilesHistoricoCaja(
  const AConexiones: IServicioConexiones;
  const AContexto: IContextoSesionAplicacion;
  const ACache: ICachePerfilesUsuario
): IGrabadorPerfilesHistoricoCaja;

implementation

uses
  System.SysUtils, System.Generics.Collections,
  Uni;

type
  TGrabadorPerfilesHistoricoCajaUniDAC = class(
    TInterfacedObject,
    IGrabadorPerfilesHistoricoCaja)
  private
    FConexiones: IServicioConexiones;
    FContexto: IContextoSesionAplicacion;
    FCache: ICachePerfilesUsuario;
    procedure GuardarPerfilesConexion(AConexion: TUniConnection;
      const APerfiles: TPerfilList;
      AConfirmables: TObjectDictionary<string, TProfileDicc>);
    function LeerPerfilConfirmable(AConexion: TUniConnection;
      const AFormulario: string): TProfileDicc;
  public
    constructor Create(
      const AConexiones: IServicioConexiones;
      const AContexto: IContextoSesionAplicacion;
      const ACache: ICachePerfilesUsuario);
    procedure Grabar(const APerfiles: TPerfilList);
  end;

resourcestring
  SErrorConexionPerfilesCajaNoCreada =
    'No se pudo crear la conexión de perfiles de Caja.';
  SErrorConexionPerfilesCajaCompartida =
    'Los perfiles de Caja requieren una conexión propia.';

function TGrabadorPerfilesHistoricoCajaUniDAC.LeerPerfilConfirmable(
  AConexion: TUniConnection; const AFormulario: string): TProfileDicc;
var
  Consulta: TUniQuery;
  Valor: TDictValue;
begin
  Result := TProfileDicc.Create;
  Consulta := TUniQuery.Create(nil);
  try
    try
      Consulta.Connection := AConexion;
      Consulta.SQL.Text :=
        'SELECT SUBKEY_USUPER, VALUE_USUPER, VALUE_TEXT_USUPER ' +
        'FROM fza_usuarios_perfiles WHERE KEY_USUPER = :CLAVE ' +
        'AND USUARIO_GRUPO_USUPER IN (:USUARIO, :GRUPO, :TODOS) ' +
        'ORDER BY SUBKEY_USUPER, CASE USUARIO_GRUPO_USUPER ' +
        'WHEN :TODOS THEN 1 WHEN :GRUPO THEN 2 WHEN :USUARIO THEN 3 END';
      Consulta.ParamByName('CLAVE').AsString := AFormulario;
      Consulta.ParamByName('USUARIO').AsString := FContexto.Identidad.Usuario;
      Consulta.ParamByName('GRUPO').AsString := FContexto.Identidad.Grupo;
      Consulta.ParamByName('TODOS').AsString := PERFIL_TODOS;
      Consulta.Open;
      while not Consulta.Eof do
      begin
        Valor.sValue := Consulta.FieldByName('VALUE_USUPER').AsString;
        Valor.sValueText :=
          Consulta.FieldByName('VALUE_TEXT_USUPER').AsWideString;
        Result.AddOrSetValue(
          Consulta.FieldByName('SUBKEY_USUPER').AsString, Valor);
        Consulta.Next;
      end;
    except
      Result.Free;
      raise;
    end;
  finally
    Consulta.Free;
  end;
end;

constructor TGrabadorPerfilesHistoricoCajaUniDAC.Create(
  const AConexiones: IServicioConexiones;
  const AContexto: IContextoSesionAplicacion;
  const ACache: ICachePerfilesUsuario);
begin
  inherited Create;
  if not Assigned(AConexiones) then
    raise EArgumentNilException.Create('AConexiones');
  if not Assigned(AContexto) then
    raise EArgumentNilException.Create('AContexto');
  if not Assigned(ACache) then
    raise EArgumentNilException.Create('ACache');
  FConexiones := AConexiones;
  FContexto := AContexto;
  FCache := ACache;
end;

procedure TGrabadorPerfilesHistoricoCajaUniDAC.GuardarPerfilesConexion(
  AConexion: TUniConnection; const APerfiles: TPerfilList;
  AConfirmables: TObjectDictionary<string, TProfileDicc>);
var
  Consulta: TUniQuery;
  Perfil: TPerfilItem;
  Par: TPair<string, TProfileDicc>;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := AConexion;
    Consulta.SQL.Text :=
      'INSERT INTO fza_usuarios_perfiles ' +
      '(USUARIO_GRUPO_USUPER, KEY_USUPER, SUBKEY_USUPER, ' +
      ' VALUE_USUPER, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES (:usuario_grupo, :clave, :subclave, :valor, ' +
      ' CURRENT_TIMESTAMP, :usuario, :usuario) ' +
      'ON DUPLICATE KEY UPDATE ' +
      ' VALUE_USUPER = VALUES(VALUE_USUPER), ' +
      ' USUARIO_MODIF = VALUES(USUARIO_MODIF)';
    Consulta.ParamByName('usuario').AsString := FContexto.Identidad.Usuario;
    AConexion.StartTransaction;
    try
      for Perfil in APerfiles do
      begin
        Consulta.ParamByName('usuario_grupo').AsString := Perfil.UserGroup;
        Consulta.ParamByName('clave').AsString := Perfil.KeyPerfil;
        Consulta.ParamByName('subclave').AsString := Perfil.SubKey;
        Consulta.ParamByName('valor').AsString := Perfil.Value;
        Consulta.ExecSQL;
      end;
      for Perfil in APerfiles do
        if not AConfirmables.ContainsKey(Perfil.KeyPerfil) then
          AConfirmables.Add(Perfil.KeyPerfil,
            LeerPerfilConfirmable(AConexion, Perfil.KeyPerfil));
      AConexion.Commit;
    except
      if AConexion.InTransaction then
        AConexion.Rollback;
      raise;
    end;
    // Las lecturas son de la conexión propia; publicar solo tras Commit.
    for Par in AConfirmables do
      FCache.ActualizarPerfilFormulario(Par.Key, Par.Value);
  finally
    Consulta.Free;
  end;
end;

procedure TGrabadorPerfilesHistoricoCajaUniDAC.Grabar(
  const APerfiles: TPerfilList);
var
  Conexion: TUniConnection;
  Confirmables: TObjectDictionary<string, TProfileDicc>;
begin
  if Assigned(APerfiles) and (APerfiles.Count > 0) then
  begin
    Confirmables := TObjectDictionary<string, TProfileDicc>.Create(
      [doOwnsValues]);
    Conexion := nil;
    try
      Conexion := FConexiones.CrearConexion(nil, uctMantenimiento);
      if not Assigned(Conexion) then
        raise EInvalidOpException.Create(SErrorConexionPerfilesCajaNoCreada);
      if Conexion = FConexiones.ConexionPrincipal then
      begin
        Conexion := nil;
        raise EInvalidOpException.Create(SErrorConexionPerfilesCajaCompartida);
      end;
      GuardarPerfilesConexion(Conexion, APerfiles, Confirmables);
    finally
      Conexion.Free;
      Confirmables.Free;
    end;
  end;
end;

function CrearGrabadorPerfilesHistoricoCaja(
  const AConexiones: IServicioConexiones;
  const AContexto: IContextoSesionAplicacion;
  const ACache: ICachePerfilesUsuario
): IGrabadorPerfilesHistoricoCaja;
begin
  Result := TGrabadorPerfilesHistoricoCajaUniDAC.Create(
    AConexiones, AContexto, ACache);
end;

end.
