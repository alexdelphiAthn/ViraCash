{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataColumnasSkuServicios                                   }
{    Tipo:       Composición de adaptadores                                    }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Enlaza los puertos de columnas SKU y tallas con una conexión UniDAC.      }
{    Los contratos y los modos de entrada no reciben TUniConnection.           }
{******************************************************************************}
unit UniDataColumnasSkuServicios;

interface

uses
  Uni, inLibColumnasSkuIntf;

function CrearServiciosColumnasSkuUniDAC(
  AConexion: TUniConnection): TServiciosColumnasSku;

implementation

uses
  System.SysUtils, System.Generics.Collections, cxGraphics,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  inLibAtributosPaleta, inLibGridArticulos,
  inLibColumnasSkuModoDesglose, inLibModoTallasIntf,
  UniDataModoTallas, UniDataGridArticulosRepositorio;

type
  TServiciosColumnasSkuUniDAC = class(
    TInterfacedObject,
    IFabricaBusquedaTallas,
    IPresentacionAtributosSku,
    ISelectorValorAtributoAnclado,
    IFabricaPersistenciaTallas,
    IFabricaModoEntradaDesglose)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function CrearBusqueda: IBusquedaSkusTallas;
    function PintarCeldaArticulo(
      ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo;
      const ACodigoArticulo, ATexto: string): Boolean;
    function Seleccionar(const ANombreAtributo: string;
      const AValores: TArray<string>; out AValor: string): Boolean;
    function SeleccionarEn(
      const ANombreAtributo: string;
      const AValores: TArray<string>;
      const AAnclaje: TAnclajeSelectorAtributo;
      out AValor: string): Boolean;
    function CrearPersistencia(
      const AConfig: TConfigPersistenciaTallas):
      TServiciosPersistenciaModoTallas;
    function CrearModoDesglose(
      const AConfig: TConfigColumnasSku): IModoEntradaGrid;
  end;

constructor TServiciosColumnasSkuUniDAC.Create(
  AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
end;

function TServiciosColumnasSkuUniDAC.CrearBusqueda:
  IBusquedaSkusTallas;
begin
  Result := CrearBusquedaSkusTallas(FConexion);
end;

function TServiciosColumnasSkuUniDAC.PintarCeldaArticulo(
  ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
  const ACodigoArticulo, ATexto: string): Boolean;
begin
  Result := PintarCeldaSwatchArticuloSiAplica(
    FConexion,
    ACanvas,
    AViewInfo,
    ACodigoArticulo,
    ATexto,
    nil);
end;

function TServiciosColumnasSkuUniDAC.Seleccionar(
  const ANombreAtributo: string; const AValores: TArray<string>;
  out AValor: string): Boolean;
var
  oAnclaje: TAnclajeSelectorAtributo;
begin
  oAnclaje := Default(TAnclajeSelectorAtributo);
  Result := SeleccionarEn(
    ANombreAtributo, AValores, oAnclaje, AValor);
end;

function TServiciosColumnasSkuUniDAC.SeleccionarEn(
  const ANombreAtributo: string; const AValores: TArray<string>;
  const AAnclaje: TAnclajeSelectorAtributo;
  out AValor: string): Boolean;
var
  Mapa: TDictionary<string, string>;
  iAncho, iArriba, iIzquierda: Integer;
  sIdVariacion: string;
begin
  sIdVariacion := '';
  Mapa := ObtenerMapaAtributosGlobal(FConexion);
  if Mapa <> nil then
    Mapa.TryGetValue(
      UpperCase(Trim(ANombreAtributo)),
      sIdVariacion);
  iIzquierda := -1;
  iArriba := -1;
  iAncho := 160;
  if AAnclaje.Valido then
  begin
    iIzquierda := AAnclaje.IzquierdaPantalla;
    iArriba := AAnclaje.ArribaPantalla;
    iAncho := AAnclaje.Ancho;
  end;
  Result := SeleccionarAvConPaleta(
    FConexion,
    sIdVariacion,
    AValores,
    '',
    AValor,
    iIzquierda,
    iArriba,
    iAncho);
end;

function TServiciosColumnasSkuUniDAC.CrearPersistencia(
  const AConfig: TConfigPersistenciaTallas):
  TServiciosPersistenciaModoTallas;
begin
  Result := CrearPersistenciaModoTallas(FConexion, AConfig);
end;

function TServiciosColumnasSkuUniDAC.CrearModoDesglose(
  const AConfig: TConfigColumnasSku): IModoEntradaGrid;
var
  Busqueda: IBusquedaSkusTallas;
  Campos: TCamposGridArt;
  Grid: TGridArticulosLineas;
  iIndice: Integer;
begin
  Campos := Default(TCamposGridArt);
  Campos.CodigoArt := AConfig.Campos.CodigoArt;
  Campos.CodigoUnidad := AConfig.Campos.CodigoUnidad;
  Campos.Descripcion := AConfig.Campos.Descripcion;
  Campos.Cantidad := AConfig.Campos.Cantidad;
  Campos.NumAtributos := AConfig.Campos.NumAtributos;
  for iIndice := 1 to 5 do
  begin
    Campos.AttrValor[iIndice] := AConfig.Campos.AttrValor[iIndice];
    Campos.AttrNombre[iIndice] := AConfig.Campos.AttrNombre[iIndice];
  end;
  if AConfig.BuscarSoloPadresEnDesglose then
    Busqueda := CrearBusquedaArticulosPadreGridUniDAC(FConexion)
  else
    Busqueda := CrearBusquedaSkusTallas(FConexion);
  Grid := TGridArticulosLineas.Create(
    FConexion,
    AConfig.View,
    AConfig.Cds,
    Campos,
    AConfig.ContextoSesion,
    AConfig.BusquedaVisual,
    Busqueda,
    CrearConsultaArticulosGridUniDAC(FConexion),
    AConfig.ValidadorArticulos,
    AConfig.LookupAtributos,
    AConfig.RegistroLog,
    AConfig.BuscarSoloPadresEnDesglose);
  try
    Grid.UsarCombosAtributos := AConfig.UsarCombosAtributos;
    Result := TModoEntradaDesglose.Create(AConfig, Grid);
    Grid := nil;
  finally
    FreeAndNil(Grid);
  end;
end;

function CrearServiciosColumnasSkuUniDAC(
  AConexion: TUniConnection): TServiciosColumnasSku;
var
  Servicios: TServiciosColumnasSkuUniDAC;
begin
  Result := Default(TServiciosColumnasSku);
  Servicios := TServiciosColumnasSkuUniDAC.Create(AConexion);
  Result.Busqueda := Servicios;
  Result.Paleta := Servicios;
  Result.PaletaAnclada := Servicios;
  Result.PersistenciaTallas := Servicios;
  Result.ModoDesglose := Servicios;
end;

end.
