{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataPermisosGrupo                                          }
{    Tipo:       Data Module                                                   }
{ Version:       1.0.0                                                         }
{   Fecha:       26/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Data module para el mantenimiento de permisos por grupo.                  }
{******************************************************************************}
unit UniDataPermisosGrupo;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, Data.DB, MemDS, DBAccess, Uni,
  UniDataGen, inLibUser;

type
  TdmPermisosGrupo = class(TdmBase)
  end;

implementation

{$R *.dfm}

initialization
  RegistrarDataModule(TdmPermisosGrupo);
end.
