{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataVerifactuLog                                           }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       12/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module del log Verifactu.                                            }
{    Consulta de fza_verifactu_eventos (eventos encadenados por hash).         }
{******************************************************************************}
unit UniDataVerifactuLog;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser, UniDataConn;

type
  TdmVerifactuLog = class(TdmBase)
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
  RegistrarDataModule(TdmVerifactuLog);
  ForceReferenceToClass(TdmVerifactuLog);
end.
