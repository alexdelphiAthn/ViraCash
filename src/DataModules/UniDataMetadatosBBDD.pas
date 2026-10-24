{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataMetadatosBBDD                                          }
{    Tipo:       Data Module                                                  }
{ Versión:       1.0.0                                                        }
{   Fecha:       04/08/2026                                                   }
{   Autor:       Alejandro Laorden Hidalgo                                    }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Datos necesarios para consultar los metadatos de la base de datos.        }
{******************************************************************************}
unit UniDataMetadatosBBDD;

interface

uses
  System.Classes, Data.DB, MemDS, DBAccess, Uni, UniDataGen;

type
  TdmMetadatosBBDD = class(TdmBase)
    unqryMetadatos: TUniQuery;
    dsMetadatos: TDataSource;
    unqryEstructura: TUniQuery;
    unqryContenido: TUniQuery;
    dsContenido: TDataSource;
    unstrdprcRefrescar: TUniStoredProc;
    procedure DataModuleCreate(Sender: TObject);
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TdmMetadatosBBDD.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryMetadatos.Connection := ConexionPrincipal;
  unqryEstructura.Connection := ConexionPrincipal;
  unqryContenido.Connection := ConexionPrincipal;
  unstrdprcRefrescar.Connection := ConexionPrincipal;
end;

end.
