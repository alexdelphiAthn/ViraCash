{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataUsuarios                                               }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de usuarios.                                                  }
{    Mantenimiento de fza_usuarios y sus grupos y empresas asignadas.          }
{******************************************************************************}
unit UniDataUsuarios;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser, UniDataConn;

type
  TdmUsuarios = class(TdmBase)
    unqryGrupos: TUniQuery;
    dsGrupos: TDataSource;
    unqryEmpresas: TUniQuery;
    dsEmpresas: TDataSource;
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure DataModuleCreate(Sender: TObject);
  private
    function UsuarioEsGrupo(sUsuario:string):boolean;
  public
    // El form empuja su dsTablaG; el DM ya no usa GetOwnerForm.
    procedure AsignarMaestroCabecera(ADataSource: TDataSource); override;
  end;

implementation

uses
  inLibCadenas, inLibMsgConfiguracion;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

function TdmUsuarios.UsuarioEsGrupo(sUsuario: string): boolean;
var
  unqrySol:TUniQuery;
begin
  unqrySol := TUniQuery.Create(Self);
  unqrySol.Connection := ConexionPrincipal;
  unqrySol.SQL.Text := 'SELECT * ' +
    '  FROM fza_usuarios_grupos ' +
    ' WHERE GRUPO_USUGRP = :grupo ';
  unqrySol.ParamByName('grupo').AsString := sUsuario;
  unqrySol.Open;
  Result := unqrySol.RecordCount > 0;
  FreeAndNil(unqrySol);
end;

procedure TdmUsuarios.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryEmpresas.Connection := ConexionPrincipal;
  unqryGrupos.Connection := ConexionPrincipal;
end;

procedure TdmUsuarios.AsignarMaestroCabecera(ADataSource: TDataSource);
begin
  inherited;
  unqryEmpresas.MasterSource := ADataSource;
end;

procedure TdmUsuarios.unqryTablaGAfterInsert(DataSet: TDataSet);
var
  fld: TField;
begin
  inherited;
  // Campos traidos por el JOIN de vi_usuarios (fza_usuarios_grupos y
  // vi_empresas): son de solo lectura y no forman parte del INSERT sobre
  // fza_usuarios. UniDAC los marca Required por ser NOT NULL en su tabla
  // origen, lo que bloquea el alta. Se desactiva la obligatoriedad.
  fld := unqryTablaG.FindField('GRUPO_USUGRP');
  if (fld <> nil) then
    fld.Required := False;
  fld := unqryTablaG.FindField('ESGRUPOADMINISTRADOR_USUGRP');
  if (fld <> nil) then
    fld.Required := False;
  fld := unqryTablaG.FindField('RAZON_SOCIAL_EMP');
  if (fld <> nil) then
    fld.Required := False;
  // Usuario nuevo activo por defecto: caja y traspasos solo listan
  // empleados con ESACTIVO_USU = 'S'.
  fld := unqryTablaG.FindField('ESACTIVO_USU');
  if (fld <> nil) then
    fld.AsString := 'S';
end;

procedure TdmUsuarios.unqryTablaGBeforePost(DataSet: TDataSet);
var
  sUsuario:string;
  bError:Boolean;
begin
  inherited;
  // Insert vacío (accidental): cancelar sin error
  if (DataSet.State = dsInsert) and
     (Trim(unqryTablaG.FindField('USUARIO_USU').AsString) = '') then
    Abort;
  bError := False;
  sUsuario := Trim(unqryTablaG.FindField('USUARIO_USU').AsString);
  if (sUsuario = '') or
     SimbolosProhibidos(sUsuario, PerfilesLectura) then
  begin
    NotificarError(Format(SErrorNombreUsuario, [sUsuario]));
    bError := True;
  end;
  if UsuarioEsGrupo(sUsuario) then
  begin
    NotificarError(Format(
      SErrorUsuarioCoincideGrupo,
      [sUsuario]));
    bError := True;
  end;
  // FZ-ISSUE-397: la fila nueva se grababa al salir de la rejilla con
  // solo el nombre: usuario activo, sin grupo y sin contraseña.
  if (not bError) and (DataSet.State = dsInsert) then
  begin
    if Trim(unqryTablaG.FieldByName('GRUPO_USU').AsString) = '' then
    begin
      NotificarError(Format(SErrorUsuarioNuevoSinGrupo, [sUsuario]));
      bError := True;
    end
    else if Trim(
      unqryTablaG.FieldByName('PASSWORD_USU').AsString) = '' then
    begin
      NotificarError(Format(SErrorUsuarioNuevoSinContrasena, [sUsuario]));
      bError := True;
    end;
  end;
  if bError then
    Abort;
end;

initialization
  RegistrarDataModule(TdmUsuarios);
  ForceReferenceToClass(TdmUsuarios);
end.
