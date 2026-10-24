{******************************************************************************}
{                                                                              }
{  Renderizado VCL del editor de lineas de caja.                               }
{                                                                              }
{******************************************************************************}
unit inMtoCajaEditorLineasRender;

interface

uses
  Uni, cxGraphics, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView;

type
  TContextoRenderEditorLineasCajaVcl = record
    Conexion: TUniConnection;
    ColumnaArticulo: TcxGridDBColumn;
  end;
  TRenderEditorLineasCajaVcl = class
  private
    FContexto: TContextoRenderEditorLineasCajaVcl;
  public
    constructor Create(
      const AContexto: TContextoRenderEditorLineasCajaVcl);
    procedure DibujarCeldaLinea(
      Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    procedure DibujarCeldaStock(
      Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
  end;

implementation

uses
  System.SysUtils, System.Variants, System.Generics.Collections,
  cxGridCustomView, inLibAtributosPaleta;

constructor TRenderEditorLineasCajaVcl.Create(
  const AContexto: TContextoRenderEditorLineasCajaVcl);
begin
  inherited Create;
  FContexto := AContexto;
end;

procedure TRenderEditorLineasCajaVcl.DibujarCeldaLinea(
  Sender: TcxCustomGridTableView;
  ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo;
  var ADone: Boolean);
var
  Mapa: TDictionary<string, string>;
  Articulo: string;
  IdValorAtributo: string;
begin
  if Assigned(AViewInfo) and Assigned(AViewInfo.Item) and
     Assigned(AViewInfo.GridRecord) and
     (AViewInfo.Item.Tag >= 1) and
     (AViewInfo.Item.Tag <= 5) then
  begin
    Articulo := VarToStr(AViewInfo.GridRecord.Values[
      FContexto.ColumnaArticulo.Index]);
    Mapa := ObtenerMapaAtributosGlobal(FContexto.Conexion);
    IdValorAtributo := '';
    if Assigned(Mapa) and
       (AViewInfo.Item is TcxGridColumn) then
      Mapa.TryGetValue(
        UpperCase(Trim(TcxGridColumn(AViewInfo.Item).Caption)),
        IdValorAtributo);
    // Solo con el atributo de la columna (articulo y luego paleta global
    // de ese atributo): el antiguo fallback generico probaba el texto
    // contra todos los atributos y una talla "100" heredaba el color
    // basico "100".
    if PintarCeldaSwatchAtributoSiAplica(
         FContexto.Conexion,
         ACanvas,
         AViewInfo,
         IdValorAtributo,
         Articulo) then
      ADone := True;
  end;
end;

procedure TRenderEditorLineasCajaVcl.DibujarCeldaStock(
  Sender: TcxCustomGridTableView;
  ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo;
  var ADone: Boolean);
begin
  // La primera columna lleva "CODART/COLOR": solo el color, nunca otro
  // atributo (una talla "100" heredaba el color basico "100").
  if Assigned(AViewInfo) and Assigned(AViewInfo.Item) and
     (AViewInfo.Item.VisibleIndex = 0) and
     PintarCeldaSwatchColorDeSkuSiAplica(
       FContexto.Conexion,
       ACanvas,
       AViewInfo) then
    ADone := True;
end;

end.
