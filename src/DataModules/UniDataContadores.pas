{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataContadores                                             }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de contadores.                                                }
{    Mantenimiento de la tabla fza_contadores para numeración automática de    }
{    documentos.                                                               }
{******************************************************************************}
unit UniDataContadores;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser,  UniDataConn;

type
  TdmContadores = class(TdmBase)
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

initialization
  RegistrarDataModule(TdmContadores);
  ForceReferenceToClass(TdmContadores);
end.
