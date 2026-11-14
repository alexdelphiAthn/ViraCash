{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataCajaArqueosHist                                        }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       26/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module del histórico de arqueos de caja.                             }
{    Contenedor de consultas sobre fza_caja_arqueos para el histórico.         }
{******************************************************************************}
unit UniDataCajaArqueosHist;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser, UniDataConn;

type
  TdmCajaArqueosHist = class(TdmBase)
    unqryRecuento: TUniQuery;
    dsRecuento: TDataSource;
  private
    { Private declarations }
  public
    procedure AsignarMaestroCabecera(ADataSource: TDataSource); override;
    procedure AbrirDetalles; override;
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmCajaArqueosHist.AsignarMaestroCabecera(
  ADataSource: TDataSource);
begin
  inherited;
  unqryRecuento.MasterSource := ADataSource;
end;

procedure TdmCajaArqueosHist.AbrirDetalles;
begin
  inherited;
  if not unqryRecuento.Active then
    unqryRecuento.Open;
end;

initialization
  RegistrarDataModule(TdmCajaArqueosHist);
  ForceReferenceToClass(TdmCajaArqueosHist);
end.
