{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPropiedades                                            }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de propiedades de artículos.                                  }
{    Mantenimiento de fza_propiedades y sus valores y artículos asociados.     }
{******************************************************************************}
unit UniDataPropiedades;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser, UniDataConn;

type
  TdmPropiedades = class(TdmBase)
    unqryArticulos: TUniQuery;
    dsArticulos: TDataSource;
    unqryValores: TUniQuery;
    dsValores: TDataSource;
    procedure unqryTablaGAfterDelete(DataSet: TDataSet);
    procedure unqryTablaGAfterPost(DataSet: TDataSet);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryValoresAfterDelete(DataSet: TDataSet);
    procedure unqryValoresAfterPost(DataSet: TDataSet);
    procedure unqryValoresBeforeDelete(DataSet: TDataSet);
    procedure unqryValoresBeforePost(DataSet: TDataSet);
  private
    FEncolarPreciosPropiedadPrestaShop: Boolean;
    FEncolarPreciosValorPrestaShop: Boolean;
  public
    { Public declarations }
  end;

implementation

uses
  System.Variants, UniDataPrestaShopEncolado;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmPropiedades.unqryTablaGAfterDelete(DataSet: TDataSet);
begin
  try
    if FEncolarPreciosPropiedadPrestaShop then
      EncolarTodosWebPrestaShop(
        TUniQuery(DataSet).Connection,
        True,
        False,
        IdentidadSesion.Usuario);
  finally
    FEncolarPreciosPropiedadPrestaShop := False;
  end;
end;

procedure TdmPropiedades.unqryTablaGAfterPost(DataSet: TDataSet);
begin
  try
    if FEncolarPreciosPropiedadPrestaShop then
      EncolarTodosWebPrestaShop(
        TUniQuery(DataSet).Connection,
        True,
        False,
        IdentidadSesion.Usuario);
  finally
    FEncolarPreciosPropiedadPrestaShop := False;
  end;
end;

procedure TdmPropiedades.unqryTablaGBeforeDelete(DataSet: TDataSet);
begin
  FEncolarPreciosPropiedadPrestaShop :=
    PropiedadAfectaDescuentoPrestaShop(
      TUniQuery(DataSet).Connection,
      DataSet.FieldByName('CODIGO_PROP_ARTPROP').AsString,
      IdentidadSesion.Usuario);
end;

procedure TdmPropiedades.unqryTablaGBeforePost(DataSet: TDataSet);
var
  sCodigoAnterior: string;
begin
  inherited;
  FEncolarPreciosPropiedadPrestaShop :=
    PropiedadAfectaDescuentoPrestaShop(
      TUniQuery(DataSet).Connection,
      DataSet.FieldByName('CODIGO_PROP_ARTPROP').AsString,
      IdentidadSesion.Usuario);
  if (not FEncolarPreciosPropiedadPrestaShop) and
     (DataSet.State = dsEdit) then
  begin
    sCodigoAnterior := VarToStr(
      DataSet.FieldByName('CODIGO_PROP_ARTPROP').OldValue);
    FEncolarPreciosPropiedadPrestaShop :=
      PropiedadAfectaDescuentoPrestaShop(
        TUniQuery(DataSet).Connection,
        sCodigoAnterior,
        IdentidadSesion.Usuario);
  end;
end;

procedure TdmPropiedades.unqryValoresAfterDelete(DataSet: TDataSet);
begin
  try
    if FEncolarPreciosValorPrestaShop then
      EncolarTodosWebPrestaShop(
        TUniQuery(DataSet).Connection,
        True,
        False,
        IdentidadSesion.Usuario);
  finally
    FEncolarPreciosValorPrestaShop := False;
  end;
end;

procedure TdmPropiedades.unqryValoresAfterPost(DataSet: TDataSet);
begin
  try
    if FEncolarPreciosValorPrestaShop or
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
    FEncolarPreciosValorPrestaShop := False;
  end;
end;

procedure TdmPropiedades.unqryValoresBeforePost(DataSet: TDataSet);
begin
  FEncolarPreciosValorPrestaShop :=
    (DataSet.State = dsEdit) and
    ValorPropiedadAfectaDescuentoPrestaShop(
      TUniQuery(DataSet).Connection,
      DataSet.FieldByName('ID_PV_ARTPROP').AsInteger,
      IdentidadSesion.Usuario);
end;

procedure TdmPropiedades.unqryValoresBeforeDelete(DataSet: TDataSet);
begin
  FEncolarPreciosValorPrestaShop :=
    ValorPropiedadAfectaDescuentoPrestaShop(
      TUniQuery(DataSet).Connection,
      DataSet.FieldByName('ID_PV_ARTPROP').AsInteger,
      IdentidadSesion.Usuario);
end;

initialization
  RegistrarDataModule(TdmPropiedades);
  ForceReferenceToClass(TdmPropiedades);
end.
