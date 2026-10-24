{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataGenFilter                                              }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module base para filtros de mantenimientos.                          }
{    Extiende TdmBase con consulta de empresas para filtros comunes a los Mtos.}
{******************************************************************************}
unit UniDataGenFilter;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni;

type
  TdmGenFilter = class(TdmBase)
    unqryEmpresas: TUniQuery;
    dsEmpresas: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

//var
//  dmGenFilter: TdmGenFilter;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TdmGenFilter.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryEmpresas.Connection := ConexionPrincipal;

  unqryEmpresas.Open;
end;

end.
