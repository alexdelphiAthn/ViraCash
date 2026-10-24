{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPropiedadesValores                                     }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de valores de propiedades.                                    }
{    Mantenimiento de fza_propiedades_valores con su lookup de propiedad padre.}
{******************************************************************************}
unit UniDataPropiedadesValores;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser;

type
  TdmPropiedadesValores = class(TdmBase)
    unqryPropiedades: TUniQuery;
    dsPropiedades: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryTablaGAfterDelete(DataSet: TDataSet);
    procedure unqryTablaGAfterPost(DataSet: TDataSet);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
  private
    FEncolarPreciosPrestaShop: Boolean;
  public
    { Public declarations }
  end;

implementation

uses
  UniDataPrestaShopEncolado;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmPropiedadesValores.unqryTablaGAfterDelete(
  DataSet: TDataSet);
begin
  try
    if FEncolarPreciosPrestaShop then
      EncolarTodosWebPrestaShop(
        TUniQuery(DataSet).Connection,
        True,
        False,
        IdentidadSesion.Usuario);
  finally
    FEncolarPreciosPrestaShop := False;
  end;
end;

procedure TdmPropiedadesValores.unqryTablaGAfterPost(
  DataSet: TDataSet);
begin
  try
    if FEncolarPreciosPrestaShop or
       ValorPropiedadAfectaDescuentoPrestaShop(
         TUniQuery(DataSet).Connection,
         DataSet.FieldByName('ID_PV_ARTPROP').AsInteger,
         IdentidadSesion.Usuario) then
      EncolarTodosWebPrestaShop(
        TUniQuery(DataSet).Connection,
        True,
        False,
        IdentidadSesion.Usuario);
  finally
    FEncolarPreciosPrestaShop := False;
  end;
end;

procedure TdmPropiedadesValores.unqryTablaGBeforePost(
  DataSet: TDataSet);
begin
  inherited;
  FEncolarPreciosPrestaShop :=
    (DataSet.State = dsEdit) and
    ValorPropiedadAfectaDescuentoPrestaShop(
      TUniQuery(DataSet).Connection,
      DataSet.FieldByName('ID_PV_ARTPROP').AsInteger,
      IdentidadSesion.Usuario);
end;

procedure TdmPropiedadesValores.unqryTablaGBeforeDelete(
  DataSet: TDataSet);
begin
  FEncolarPreciosPrestaShop :=
    ValorPropiedadAfectaDescuentoPrestaShop(
      TUniQuery(DataSet).Connection,
      DataSet.FieldByName('ID_PV_ARTPROP').AsInteger,
      IdentidadSesion.Usuario);
end;

procedure TdmPropiedadesValores.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryPropiedades.Connection := ConexionPrincipal;
  if not unqryPropiedades.Active then
    unqryPropiedades.Open;
end;

initialization
  RegistrarDataModule(TdmPropiedadesValores);
  ForceReferenceToClass(TdmPropiedadesValores);
end.
