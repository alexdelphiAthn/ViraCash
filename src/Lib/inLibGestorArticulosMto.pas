{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGestorArticulosMto                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Coordina foto, stock y artículo/SKU activo de los mantenimientos.         }
{******************************************************************************}
unit inLibGestorArticulosMto;

interface

uses
  System.SysUtils, Data.DB;

type
  TResolverArtSkuMto =
    procedure(out ACodArt, ACodSku: string) of object;
  TObtenerDataSourcesFotoMto =
    function: TArray<TDataSource> of object;
  TConsultarFotoVisibleMto =
    function: Boolean of object;
  TAccionFotoMto =
    procedure of object;
  TMostrarArtSkuMto =
    procedure(const ACodArt, ACodSku: string) of object;
  TVincularDataSourcesFotoMto =
    procedure(const ADataSources: TArray<TDataSource>) of object;

  TGestorArticulosMto = class
  private
    FDataSourcePrincipal: TDataSource;
    FResolverActivo: TResolverArtSkuMto;
    FObtenerDataSources: TObtenerDataSourcesFotoMto;
    FConsultarFotoVisible: TConsultarFotoVisibleMto;
    FOcultarFoto: TAccionFotoMto;
    FMostrarFoto: TMostrarArtSkuMto;
    FVincularFoto: TVincularDataSourcesFotoMto;
    FMostrarStock: TMostrarArtSkuMto;
  public
    constructor Create(
      ADataSourcePrincipal: TDataSource;
      AResolverActivo: TResolverArtSkuMto;
      AObtenerDataSources: TObtenerDataSourcesFotoMto;
      AConsultarFotoVisible: TConsultarFotoVisibleMto;
      AOcultarFoto: TAccionFotoMto;
      AMostrarFoto: TMostrarArtSkuMto;
      AVincularFoto: TVincularDataSourcesFotoMto;
      AMostrarStock: TMostrarArtSkuMto);
    procedure AlternarFoto;
    procedure ConsultarStock;
    procedure DesvincularFoto;
    procedure ResolverPorDefecto(
      out ACodArt, ACodSku: string);
    function DataSourcesPorDefecto: TArray<TDataSource>;
  end;

implementation

uses
  inLibFotos;

constructor TGestorArticulosMto.Create(
  ADataSourcePrincipal: TDataSource;
  AResolverActivo: TResolverArtSkuMto;
  AObtenerDataSources: TObtenerDataSourcesFotoMto;
  AConsultarFotoVisible: TConsultarFotoVisibleMto;
  AOcultarFoto: TAccionFotoMto;
  AMostrarFoto: TMostrarArtSkuMto;
  AVincularFoto: TVincularDataSourcesFotoMto;
  AMostrarStock: TMostrarArtSkuMto);
begin
  inherited Create;
  FDataSourcePrincipal := ADataSourcePrincipal;
  FResolverActivo := AResolverActivo;
  FObtenerDataSources := AObtenerDataSources;
  FConsultarFotoVisible := AConsultarFotoVisible;
  FOcultarFoto := AOcultarFoto;
  FMostrarFoto := AMostrarFoto;
  FVincularFoto := AVincularFoto;
  FMostrarStock := AMostrarStock;
end;

procedure TGestorArticulosMto.AlternarFoto;
var
  aDataSources: TArray<TDataSource>;
  bFotoVisible: Boolean;
  sArt: string;
  sSku: string;
begin
  bFotoVisible := False;
  if Assigned(FConsultarFotoVisible) then
    bFotoVisible := FConsultarFotoVisible;
  if bFotoVisible then
  begin
    if Assigned(FOcultarFoto) then
      FOcultarFoto;
  end
  else
  begin
    sArt := '';
    sSku := '';
    if Assigned(FResolverActivo) then
      FResolverActivo(sArt, sSku);
    if sArt <> '' then
    begin
      if Assigned(FMostrarFoto) then
        FMostrarFoto(sArt, sSku);
      if Assigned(FObtenerDataSources) and
         Assigned(FVincularFoto) then
      begin
        aDataSources := FObtenerDataSources;
        FVincularFoto(aDataSources);
      end;
    end;
  end;
end;

procedure TGestorArticulosMto.ConsultarStock;
var
  sArt: string;
  sSku: string;
begin
  sArt := '';
  sSku := '';
  if Assigned(FResolverActivo) then
    FResolverActivo(sArt, sSku);
  if Assigned(FMostrarStock) then
    FMostrarStock(sArt, sSku);
end;

procedure TGestorArticulosMto.DesvincularFoto;
var
  aDataSources: TArray<TDataSource>;
begin
  aDataSources := nil;
  if Assigned(FVincularFoto) then
    FVincularFoto(aDataSources);
end;

procedure TGestorArticulosMto.ResolverPorDefecto(
  out ACodArt, ACodSku: string);
begin
  ACodArt := '';
  ACodSku := '';
  if Assigned(FDataSourcePrincipal) and
     Assigned(FDataSourcePrincipal.DataSet) then
    inLibFotos.LeerArtSkuDeDataSet(
      FDataSourcePrincipal.DataSet, ACodArt, ACodSku);
end;

function TGestorArticulosMto.DataSourcesPorDefecto:
  TArray<TDataSource>;
begin
  Result := [FDataSourcePrincipal];
end;

end.
