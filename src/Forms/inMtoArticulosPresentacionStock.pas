{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoArticulosPresentacionStock                               }
{    Tipo:       Colaborador VCL                                               }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Paleta basica de la rejilla de stock pivotado: mapa de atributos del      }
{    articulo, cuadrados de color, hints y ancho de columna. Recibe la vista   }
{    y la conexion de lectura, nunca el formulario.                            }
{******************************************************************************}
unit inMtoArticulosPresentacionStock;

interface

uses
  System.SysUtils, System.Types, System.Generics.Collections,
  Uni,
  cxGraphics, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView;

type
  TPresentadorStockArticulo = class
  private
    // NOMBRE_ATRIBUTO (uppercase) -> ID_ATRIBUTO del articulo actual.
    FAtributos: TDictionary<string, string>;
    FVista: TcxGridDBTableView;
    FConexion: TUniConnection;
    function ResolverIdVariacion(AItem: TcxCustomGridTableItem;
      out AIdVariacion: string): Boolean;
  public
    constructor Create(AVista: TcxGridDBTableView;
      AConexion: TUniConnection);
    destructor Destroy; override;
    procedure CargarMapaArticulo(const ACodigoArticulo: string);
    procedure PintarCelda(ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo; var AHecho: Boolean);
    function ObtenerHint(AViewInfo: TcxGridTableDataCellViewInfo;
      out AHint: string): Boolean;
    procedure EnsancharColumnasParaSwatch;
  end;

implementation

uses
  inLibDevExp,
  inLibAtributosPaleta,
  inLibAtributosPaletaIntf;

constructor TPresentadorStockArticulo.Create(AVista: TcxGridDBTableView;
  AConexion: TUniConnection);
begin
  inherited Create;
  FVista := AVista;
  FConexion := AConexion;
  FAtributos := TDictionary<string, string>.Create;
end;

destructor TPresentadorStockArticulo.Destroy;
begin
  FreeAndNil(FAtributos);
  inherited Destroy;
end;

procedure TPresentadorStockArticulo.CargarMapaArticulo(
  const ACodigoArticulo: string);
begin
  // Debe correr ANTES de reconstruir las columnas dinamicas: el bestfit
  // necesita saber que columnas pintaran swatch para reservarles ancho.
  if FAtributos <> nil then
    CargarMapaAtributosArticulo(FConexion, ACodigoArticulo, FAtributos);
end;

function TPresentadorStockArticulo.ResolverIdVariacion(
  AItem: TcxCustomGridTableItem; out AIdVariacion: string): Boolean;
begin
  AIdVariacion := '';
  Result := (FAtributos <> nil) and (FAtributos.Count > 0) and
            (AItem <> nil);
  if Result then
    // El nombre de campo casa con NOMBRE_VA porque el SP de stock
    // pivotado etiqueta la fila desglosada con ese mismo nombre. Las
    // columnas pivote (S, M, 3, 5, ...) no estan en el diccionario.
    Result := FAtributos.TryGetValue(
      UpperCase(Trim(GetItemFieldName(AItem))), AIdVariacion);
end;

procedure TPresentadorStockArticulo.PintarCelda(ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var AHecho: Boolean);
var
  oInfo: TInfoBasico;
  sIdVariacion: string;
begin
  if AViewInfo <> nil then
  begin
    if ResolverIdVariacion(AViewInfo.Item, sIdVariacion) then
    begin
      if ObtenerInfoBasico(FConexion, sIdVariacion, AViewInfo.Text,
           oInfo) then
      begin
        if PintarCeldaConCuadradoColor(ACanvas, AViewInfo, oInfo) then
          AHecho := True;
      end;
    end;
  end;
end;

function TPresentadorStockArticulo.ObtenerHint(
  AViewInfo: TcxGridTableDataCellViewInfo; out AHint: string): Boolean;
var
  oInfo: TInfoBasico;
  sIdVariacion: string;
begin
  AHint := '';
  Result := False;
  if AViewInfo <> nil then
  begin
    if ResolverIdVariacion(AViewInfo.Item, sIdVariacion) then
    begin
      Result := ObtenerInfoBasico(FConexion, sIdVariacion, AViewInfo.Text,
        oInfo);
      if Result then
        AHint := oInfo.Nombre;
    end;
  end;
end;

procedure TPresentadorStockArticulo.EnsancharColumnasParaSwatch;
var
  iColumna: Integer;
begin
  // Solo se ensanchan las columnas que van a pintar swatch. ApplyBestFit
  // mide texto y no reserva sitio para el cuadradito de color.
  if (FVista <> nil) and (FAtributos <> nil) and (FAtributos.Count > 0) then
  begin
    for iColumna := 0 to FVista.ColumnCount - 1 do
      if FAtributos.ContainsKey(
           UpperCase(Trim(GetItemFieldName(FVista.Columns[iColumna])))) then
        AjustarAnchoColumnaParaSwatch(
          FConexion, FVista.Columns[iColumna], FAtributos);
  end;
end;

end.
