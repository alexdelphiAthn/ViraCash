{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataLogonRepositorio                                       }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Persistencia y componentes UniDAC usados por la pantalla de logon.       }
{******************************************************************************}
unit UniDataLogonRepositorio;

interface

uses
  System.Classes, Uni,
  inLibConexionesIntf,
  inLibLogonAplicacionIntf;

procedure CrearRepositorioLogonUniDAC(
  const AFabricaConexiones: IFabricaConexionesUniDAC;
  out ARepositorio: IRepositorioLogon;
  out AConexion: TUniConnection);
function ExisteEsquemaLogonUniDAC(
  AConexion: TUniConnection;
  const ABaseDatos: string): Boolean;
procedure EjecutarScriptLogonUniDAC(
  AConexion: TUniConnection;
  const ARuta: string;
  const AResolverError: TResolverErrorScriptLogon);

implementation

uses
  System.SysUtils, Data.DB, DBAccess,
  DAScript, UniScript, inLibMsgConexion, inLibMsgLogon,
  inLibNuevoEquipo, inLibProteccionDatosFacturacion, inLibWin;

const
  SQL_AUTENTICAR =
    'SELECT U.PASSWORD_USU, U.EMPRESA_DEFECTO_USU, ' +
    'U.ALMACEN_DEFECTO_USU, U.CAJA_DEFECTO_USU, ' +
    'V.GRUPO_USU, V.ESGRUPOADMINISTRADOR_USUGRP ' +
    'FROM fza_usuarios U LEFT JOIN vi_usuarios V ' +
    'ON V.USUARIO_USU = U.USUARIO_USU ' +
    'WHERE U.USUARIO_USU = :Usuario';
  SQL_ULTIMO_LOGIN =
    'UPDATE fza_usuarios SET ULTIMO_LOGIN_USU = :Instante ' +
    'WHERE USUARIO_USU = :Usuario';
  SQL_VALIDAR_USUARIO_NUEVO_EQUIPO =
    'SELECT U.PASSWORD_USU AS CONTRASENA, ' +
    'COALESCE(U.ESACTIVO_USU, ''N'') AS ACTIVO, ' +
    'COALESCE(G.ESGRUPOADMINISTRADOR_USUGRP, ''N'') AS ADMINISTRADOR ' +
    'FROM fza_usuarios U LEFT JOIN fza_usuarios_grupos G ' +
    'ON G.GRUPO_USUGRP = U.GRUPO_USU ' +
    'WHERE U.USUARIO_USU = :Usuario';
  SQL_ESTABLECER_CONTRASENA_NUEVO_EQUIPO =
    'UPDATE fza_usuarios SET PASSWORD_USU = :Contrasena, ' +
    'INSTANTE_MODIF = :Instante, USUARIO_MODIF = :UsuarioModif ' +
    'WHERE USUARIO_USU = :Usuario ' +
    'AND COALESCE(ESACTIVO_USU, ''N'') = ''S'' ' +
    'AND EXISTS (SELECT 1 FROM fza_usuarios_grupos G ' +
    'WHERE G.GRUPO_USUGRP = fza_usuarios.GRUPO_USU ' +
    'AND COALESCE(G.ESGRUPOADMINISTRADOR_USUGRP, ''N'') = ''S'')';
  SQL_EXIGIR_CONTRASENA_INICIAL_DEMO =
    ' AND PASSWORD_USU = :ContrasenaDemoInicial';
  SQL_EXISTE_ESQUEMA =
    'SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA ' +
    'WHERE SCHEMA_NAME = :BBDD';
  USUARIO_AUDITORIA_NUEVO_EQUIPO = 'Mantenimiento';
  { Debe coincidir con Administrador en factuzam_demo.sql. Sólo limita la
    marca automática del instalador; el conmutador manual no la exige. }
  HASH_CONTRASENA_INICIAL_DEMO =
    '4F8239A5B05A0E22D3DD4D7853808AF3';

type
  TRepositorioLogonUniDAC = class(
    TInterfacedObject,
    IRepositorioLogon)
  private
    FFabricaConexiones: IFabricaConexionesUniDAC;
    FConexion: TUniConnection;
  public
    constructor Create(
      const AFabricaConexiones: IFabricaConexionesUniDAC);
    destructor Destroy; override;
    function Autenticar(
      const AUsuario, AContrasena: string): TResultadoAutenticacionLogon;
    procedure EstablecerContrasenaNuevoEquipo(
      const AUsuario, AContrasenaNueva: string;
      AExigirContrasenaDemoInicial: Boolean = False);
    property Conexion: TUniConnection read FConexion;
  end;

  TEjecutorScriptLogonUniDAC = class
  private
    FResolverError: TResolverErrorScriptLogon;
    procedure ResolverError(
      Sender: TObject;
      E: Exception;
      SQL: string;
      var Action: TErrorAction);
  public
    procedure Ejecutar(
      AConexion: TUniConnection;
      const ARuta: string;
      const AResolverError: TResolverErrorScriptLogon);
  end;

procedure ComprobarConexion(AConexion: TUniConnection);
begin
  if AConexion = nil then
    raise EArgumentNilException.Create(
      SErrorConexionNoAsignada);
end;

procedure CrearRepositorioLogonUniDAC(
  const AFabricaConexiones: IFabricaConexionesUniDAC;
  out ARepositorio: IRepositorioLogon;
  out AConexion: TUniConnection);
var
  oRepositorio: TRepositorioLogonUniDAC;
begin
  oRepositorio := TRepositorioLogonUniDAC.Create(
    AFabricaConexiones);
  AConexion := oRepositorio.Conexion;
  ARepositorio := oRepositorio;
end;

constructor TRepositorioLogonUniDAC.Create(
  const AFabricaConexiones: IFabricaConexionesUniDAC);
begin
  if not Assigned(AFabricaConexiones) then
    raise EArgumentNilException.Create(
      SErrorFabricaConexionesNoAsignada);
  inherited Create;
  FFabricaConexiones := AFabricaConexiones;
  FConexion := FFabricaConexiones.CrearConexion(nil);
  ComprobarConexion(FConexion);
end;

destructor TRepositorioLogonUniDAC.Destroy;
begin
  FreeAndNil(FConexion);
  FFabricaConexiones := nil;
  inherited;
end;

function TRepositorioLogonUniDAC.Autenticar(
  const AUsuario, AContrasena: string): TResultadoAutenticacionLogon;
var
  oConsulta: TUniQuery;
  sClaveEsperada: string;
  sClaveIntroducida: string;
begin
  if not FConexion.Connected then
    raise ERepositorioLogonNoDisponible.Create(
      SErrorBaseDatosAutenticacionNoDisponible);
  Result := TResultadoAutenticacionLogon.Crear(
    ealCredencialesInvalidas,
    SResultadoCredencialesInvalidas);
  oConsulta := TUniQuery.Create(nil);
  try
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text :=
        FFabricaConexiones.DialectoSql.AplicarLimiteOrdenado(
          SQL_AUTENTICAR, 'U.USUARIO_USU', 1);
      oConsulta.ParamByName('Usuario').AsString := AUsuario;
      oConsulta.Open;
      if not oConsulta.IsEmpty then
      begin
        sClaveEsperada := oConsulta.FieldByName('PASSWORD_USU').AsString;
        sClaveIntroducida := '';
        if AContrasena <> '' then
          sClaveIntroducida := sMd5(AContrasena);
        if sClaveIntroducida = sClaveEsperada then
        begin
          Result := TResultadoAutenticacionLogon.Crear(
            ealAutenticado,
            SResultadoAutenticacionCorrecta);
          Result.Usuario := AUsuario;
          Result.Grupo := oConsulta.FieldByName('GRUPO_USU').AsString;
          Result.EsGrupoAdministrador := oConsulta.FieldByName(
            'ESGRUPOADMINISTRADOR_USUGRP').AsString;
          Result.Empresa := oConsulta.FieldByName(
            'EMPRESA_DEFECTO_USU').AsString;
          Result.Almacen := oConsulta.FieldByName(
            'ALMACEN_DEFECTO_USU').AsString;
          Result.Caja := oConsulta.FieldByName('CAJA_DEFECTO_USU').AsString;
          oConsulta.Close;
          oConsulta.SQL.Text := SQL_ULTIMO_LOGIN;
          oConsulta.ParamByName('Instante').AsDateTime := Now;
          oConsulta.ParamByName('Usuario').AsString := AUsuario;
          oConsulta.ExecSQL;
        end;
      end;
    except
      on E: Exception do
      begin
        if not FConexion.Connected then
          raise ERepositorioLogonNoDisponible.Create(E.Message)
        else
          raise ERepositorioLogonError.Create(E.Message);
      end;
    end;
  finally
    oConsulta.Free;
  end;
end;

procedure TRepositorioLogonUniDAC.EstablecerContrasenaNuevoEquipo(
  const AUsuario, AContrasenaNueva: string;
  AExigirContrasenaDemoInicial: Boolean);
var
  bTransaccionPropia: Boolean;
  oConsulta: TUniQuery;
  sContrasenaCifrada: string;
begin
  if not FConexion.Connected then
    raise ERepositorioLogonNoDisponible.Create(
      SErrorBaseDatosAutenticacionNoDisponible);
  if not SameText(
           Trim(AUsuario),
           USUARIO_INICIAL_NUEVO_EQUIPO) then
    raise EArgumentException.Create('AUsuario');
  if AContrasenaNueva = '' then
    raise EArgumentException.Create('AContrasenaNueva');
  sContrasenaCifrada := sMd5(AContrasenaNueva);
  if AExigirContrasenaDemoInicial and
     SameText(sContrasenaCifrada, HASH_CONTRASENA_INICIAL_DEMO) then
  begin
    raise ERepositorioLogonError.Create(
      SErrorContrasenaNuevoEquipoDebeDiferirDemo);
  end;
  oConsulta := TUniQuery.Create(nil);
  try
    try
      oConsulta.Connection := FConexion;
      bTransaccionPropia := not FConexion.InTransaction;
      if bTransaccionPropia then
        FConexion.StartTransaction;
      try
        { Las condiciones de activo y administrador forman parte del UPDATE;
          no se concede el restablecimiento a partir de una comprobación
          anterior que pudiera quedar obsoleta. }
        oConsulta.SQL.Text := SQL_ESTABLECER_CONTRASENA_NUEVO_EQUIPO;
        if AExigirContrasenaDemoInicial then
        begin
          oConsulta.SQL.Add(SQL_EXIGIR_CONTRASENA_INICIAL_DEMO);
          oConsulta.ParamByName('ContrasenaDemoInicial').AsString :=
            HASH_CONTRASENA_INICIAL_DEMO;
        end;
        oConsulta.ParamByName('Contrasena').AsString :=
          sContrasenaCifrada;
        oConsulta.ParamByName('Instante').AsDateTime := Now;
        oConsulta.ParamByName('UsuarioModif').AsString :=
          USUARIO_AUDITORIA_NUEVO_EQUIPO;
        oConsulta.ParamByName('Usuario').AsString := AUsuario;
        oConsulta.ExecSQL;

        { RowsAffected puede ser cero si se repite la misma clave dentro de
          la precisión temporal de la BBDD. Se verifica el estado final. }
        oConsulta.SQL.Text := SQL_VALIDAR_USUARIO_NUEVO_EQUIPO;
        oConsulta.ParamByName('Usuario').AsString := AUsuario;
        oConsulta.Open;
        if oConsulta.IsEmpty or
           not SameText(
             oConsulta.FieldByName('ACTIVO').AsString,
             'S') or
           not SameText(
             oConsulta.FieldByName('ADMINISTRADOR').AsString,
             'S') then
        begin
          raise ERepositorioLogonError.CreateFmt(
            SErrorUsuarioNuevoEquipoNoAutorizado,
            [AUsuario]);
        end;
        if not SameText(
                 oConsulta.FieldByName('CONTRASENA').AsString,
                 sContrasenaCifrada) then
        begin
          if AExigirContrasenaDemoInicial and
             not SameText(
               oConsulta.FieldByName('CONTRASENA').AsString,
               HASH_CONTRASENA_INICIAL_DEMO) then
          begin
            raise ENuevoEquipoDemoYaPreparado.Create(
              SAvisoNuevoEquipoDemoYaPreparado);
          end;
          raise ERepositorioLogonError.CreateFmt(
            SErrorContrasenaNuevoEquipoNoVerificada,
            [AUsuario]);
        end;
        oConsulta.Close;
        if bTransaccionPropia and FConexion.InTransaction then
          FConexion.Commit;
      except
        if bTransaccionPropia and FConexion.InTransaction then
          FConexion.Rollback;
        raise;
      end;
    except
      on E: ERepositorioLogonError do
        raise;
      on E: Exception do
      begin
        if not FConexion.Connected then
          raise ERepositorioLogonNoDisponible.Create(E.Message)
        else
          raise ERepositorioLogonError.Create(E.Message);
      end;
    end;
  finally
    oConsulta.Free;
  end;
end;

function ExisteEsquemaLogonUniDAC(
  AConexion: TUniConnection;
  const ABaseDatos: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  ComprobarConexion(AConexion);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := SQL_EXISTE_ESQUEMA;
    oConsulta.ParamByName('BBDD').AsString := ABaseDatos;
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
  finally
    oConsulta.Free;
  end;
end;

procedure TEjecutorScriptLogonUniDAC.ResolverError(
  Sender: TObject;
  E: Exception;
  SQL: string;
  var Action: TErrorAction);
begin
  Action := eaFail;
  if Assigned(FResolverError) and
     (FResolverError(SQL, E.Message) = deslContinuar) then
    Action := eaContinue;
end;

procedure TEjecutorScriptLogonUniDAC.Ejecutar(
  AConexion: TUniConnection;
  const ARuta: string;
  const AResolverError: TResolverErrorScriptLogon);
var
  oScript: TUniScript;
begin
  ComprobarConexion(AConexion);
  FResolverError := AResolverError;
  oScript := TUniScript.Create(nil);
  try
    oScript.Connection := AConexion;
    oScript.NoPreconnect := True;
    oScript.OnError := ResolverError;
    oScript.SQL.LoadFromFile(ARuta);
    ValidarSqlSinModificacionesFacturacion(oScript.SQL.Text);
    oScript.Execute;
  finally
    oScript.Free;
  end;
end;

procedure EjecutarScriptLogonUniDAC(
  AConexion: TUniConnection;
  const ARuta: string;
  const AResolverError: TResolverErrorScriptLogon);
var
  oEjecutor: TEjecutorScriptLogonUniDAC;
begin
  oEjecutor := TEjecutorScriptLogonUniDAC.Create;
  try
    oEjecutor.Ejecutar(AConexion, ARuta, AResolverError);
  finally
    oEjecutor.Free;
  end;
end;

end.
