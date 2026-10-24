{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataGrupos                                                 }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de grupos de usuarios.                                        }
{    Mantenimiento de fza_usuarios_grupos y consulta de usuarios asociados al  }
{    grupo.                                                                    }
{******************************************************************************}
unit UniDataGrupos;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser;

type
  TdmGrupos = class(TdmBase)
    unqryUsuariosGrupo: TUniQuery;
    dsUsuariosGrupo: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure AbrirDetalles; override;
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses System.Diagnostics;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmGrupos.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryUsuariosGrupo.Connection := ConexionPrincipal;
  unqryTablaG.Connection := ConexionPrincipal;
  // unqryUsuariosGrupo.Open movido a AbrirDetalles.
end;

procedure TdmGrupos.AbrirDetalles;
var
  swQ: TStopwatch;
begin
  inherited;
  if not unqryUsuariosGrupo.Active then
  begin
    swQ := TStopwatch.StartNew;
    try
      unqryUsuariosGrupo.Open;
      RegistroLog.RegistrarRendimiento('Grupos.AbrirDetalles',
        'unqryUsuariosGrupo OK', swQ.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        RegistroLog.RegistrarRendimiento('Grupos.AbrirDetalles',
          'unqryUsuariosGrupo ERROR=' + E.Message,
          swQ.ElapsedMilliseconds);
        raise;
      end;
    end;
  end;
end;

initialization
  RegistrarDataModule(TdmGrupos);
  ForceReferenceToClass(TdmGrupos);
end.
