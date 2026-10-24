{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPerfilesMtoRepositorio                                }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Adaptador UniDAC de persistencia para perfiles de mantenimientos.        }
{******************************************************************************}
unit UniDataPerfilesMtoRepositorio;

interface

uses
  Uni, inLibPerfilesMtoPersistenciaIntf;

function CrearPersistenciaPerfilesMtoUniDAC(
  AConexionGuardado: TUniConnection;
  AConexionConsulta: TUniConnection;
  AConsulta: TUniQuery
): IPersistenciaPerfilesMto;

implementation

uses
  System.SysUtils;

const
  SQL_PERFILES_FORMULARIO =
    'SELECT * FROM fza_usuarios_perfiles ' +
    'WHERE KEY_USUPER = :NameFormModule';
  SQL_PERFILES_FORMULARIO_DATOS =
    'SELECT * FROM fza_usuarios_perfiles ' +
    'WHERE (KEY_USUPER = :NameDataModule) ' +
    'OR (KEY_USUPER = :NameFormModule)';

type
  TPersistenciaPerfilesMtoUniDAC = class(
    TInterfacedObject,
    IPersistenciaPerfilesMto)
  private
    FConexionGuardado: TUniConnection;
    FConexionConsulta: TUniConnection;
    FConsulta: TUniQuery;
    function NecesitaConsultaFormulario: Boolean;
    function NecesitaConsultaDataModule: Boolean;
  public
    constructor Create(
      AConexionGuardado: TUniConnection;
      AConexionConsulta: TUniConnection;
      AConsulta: TUniQuery);
    destructor Destroy; override;
    procedure GuardarAtomico(const AGuardado: TProc);
    procedure AbrirPerfiles(
      const AFormulario, ADataModule: string);
  end;

constructor TPersistenciaPerfilesMtoUniDAC.Create(
  AConexionGuardado: TUniConnection;
  AConexionConsulta: TUniConnection;
  AConsulta: TUniQuery);
begin
  inherited Create;
  if not Assigned(AConexionGuardado) then
    raise EArgumentNilException.Create('AConexionGuardado');
  if not Assigned(AConexionConsulta) then
    raise EArgumentNilException.Create('AConexionConsulta');
  if not Assigned(AConsulta) then
    raise EArgumentNilException.Create('AConsulta');
  FConexionGuardado := AConexionGuardado;
  FConexionConsulta := AConexionConsulta;
  FConsulta := AConsulta;
end;

destructor TPersistenciaPerfilesMtoUniDAC.Destroy;
begin
  FConsulta := nil;
  FConexionConsulta := nil;
  FConexionGuardado := nil;
  inherited;
end;

function TPersistenciaPerfilesMtoUniDAC.
  NecesitaConsultaFormulario: Boolean;
begin
  Result := (Pos('Nothing', FConsulta.SQL.Text) > 0) or
            (Trim(FConsulta.SQL.Text) = '');
end;

function TPersistenciaPerfilesMtoUniDAC.
  NecesitaConsultaDataModule: Boolean;
begin
  Result := NecesitaConsultaFormulario or
            (Pos(':NameDataModule', FConsulta.SQL.Text) > 0);
end;

procedure TPersistenciaPerfilesMtoUniDAC.GuardarAtomico(
  const AGuardado: TProc);
var
  EsTransaccionPropia: Boolean;
begin
  if not Assigned(AGuardado) then
    raise EArgumentNilException.Create('AGuardado');
  EsTransaccionPropia := not FConexionGuardado.InTransaction;
  if EsTransaccionPropia then
    FConexionGuardado.StartTransaction;
  try
    AGuardado;
    if EsTransaccionPropia and
       FConexionGuardado.InTransaction then
      FConexionGuardado.Commit;
  except
    if EsTransaccionPropia and
       FConexionGuardado.InTransaction then
      FConexionGuardado.Rollback;
    raise;
  end;
end;

procedure TPersistenciaPerfilesMtoUniDAC.AbrirPerfiles(
  const AFormulario, ADataModule: string);
begin
  if ADataModule = '' then
  begin
    if NecesitaConsultaFormulario then
    begin
      FConsulta.SQL.Text := SQL_PERFILES_FORMULARIO;
      FConsulta.ParamByName(
        'NameFormModule').AsString := AFormulario;
    end;
  end
  else if NecesitaConsultaDataModule then
  begin
    FConsulta.SQL.Text := SQL_PERFILES_FORMULARIO_DATOS;
    FConsulta.ParamByName(
      'NameDataModule').AsString := AFormulario;
    FConsulta.ParamByName(
      'NameFormModule').AsString := ADataModule;
  end;
  if not FConsulta.Active then
  begin
    FConsulta.Connection := FConexionConsulta;
    FConsulta.Open;
  end;
end;

function CrearPersistenciaPerfilesMtoUniDAC(
  AConexionGuardado: TUniConnection;
  AConexionConsulta: TUniConnection;
  AConsulta: TUniQuery
): IPersistenciaPerfilesMto;
begin
  Result := TPersistenciaPerfilesMtoUniDAC.Create(
    AConexionGuardado, AConexionConsulta,
    AConsulta);
end;

end.
