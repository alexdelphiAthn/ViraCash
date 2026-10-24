{******************************************************************************}
{                                                                              }
{  Módulo:       inLibDocumentosTrabajoExcel                                   }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       23/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Exporta un Documento de Trabajo a Excel con una foto de 150 x 150 por     }
{    cada línea, resuelta por artículo y SKU. Las líneas sin foto mantienen    }
{    una altura compacta.                                                      }
{******************************************************************************}
unit inLibDocumentosTrabajoExcel;

interface

uses
  System.SysUtils, System.Classes, System.Types,
  System.Generics.Collections, Data.DB, Vcl.Graphics, cxGraphics,
  dxSpreadSheet, dxSpreadSheetCore, dxSpreadSheetTypes,
  dxSpreadSheetContainers, dxSpreadSheetGraphics, dxSpreadSheetStyles,
  dxCoreGraphics, dxHashUtils, dxGDIPlusClasses, dxSmartImage,
  inLibDevExcel, inLibFotos;

procedure ExportarDocumentoTrabajoExcel(
  ASheetControl: TdxSpreadSheet;
  const QCabecera, QLineas: TDataSet;
  AFotos: TFotosArticulos);

implementation

const
  fidDtr = 'ID_DTR';
  ftituloDtr = 'TITULO_DTR';
  ftipoDtr = 'TIPO_DTR';
  festadoDtr = 'ESTADO_DTR';
  fcodEmpDtr = 'CODIGO_EMP_DTR';
  fcodAlmDtr = 'CODIGO_ALM_DTR';
  fusuarioDtr = 'USUARIO_DTR';
  finstanteDtr = 'INSTANTE_DOCUMENTO_DTR';
  flineaDtl = 'LINEA_DTL';
  fcodArtDtl = 'CODIGO_ART_DTL';
  fcodUnidadDtl = 'CODIGO_UNIDAD_DTL';
  fcodAlmDtl = 'CODIGO_ALM_DTL';
  fdescripcionArtDtl = 'DESCRIPCION_ARTICULO_DTL';
  frefProveedor = 'REF_PROVEEDOR';
  fcodFamilia = 'CODIGO_FAM_ART';
  ffamilia = 'DESCRIPCION_FAM';
  fcodProveedor = 'CODIGO_PRV_AP';
  fproveedor = 'NOMBRE_PRV';
  ftemporada = 'TEMPORADA_ART';
  fcodTarifa = 'CODIGO_TAR_ARTTAR';
  ftarifa = 'NOMBRE_TAR_TAR';
  fprecioTarifa = 'PRECIO_FINAL_ARTTAR';
  fdescripcionUnidadDtl = 'DESCRIPCION_UNIDAD_DTL';
  fcantidadStockDtl = 'CANTIDAD_STOCK_DTL';
  fcantidadDtl = 'CANTIDAD_DTL';
  forigenDtl = 'ORIGEN_DTL';
  finstanteStockDtl = 'INSTANTE_STOCK_DTL';
  cTamanoFoto = 150;
  cFormatoCantidad = '#,##0.##;-#,##0.##;0';
  cFormatoPrecio = '#,##0.00" €"';
  cColorCabecera = $00666666;

type
  TExportadorDocumentoTrabajo = class
  private
    FControl: TdxSpreadSheet;
    FCabecera: TDataSet;
    FLineas: TDataSet;
    FFotos: TFotosArticulos;
    FHoja: TdxSpreadSheetTableView;
    FFotosLinea: TDictionary<string, TFotoInfo>;
    FFila: Integer;
    function TextoCodigoNombre(const ACodigo, ANombre: string): string;
    procedure EscribirFecha(AFila, AColumna: Integer; ACampo: TField);
    procedure IncrustarFoto(AFila: Integer; const ACodArt, ACodSku: string);
    procedure EscribirCabeceraDocumento;
    procedure EscribirCabeceraLineas;
    procedure EscribirLinea;
    procedure ProcesarLineas;
    procedure ConfigurarAnchos;
  public
    constructor Create(AControl: TdxSpreadSheet;
      const ACabecera, ALineas: TDataSet; AFotos: TFotosArticulos);
    procedure Ejecutar;
  end;

const
  COL_FOTO = 0;
  COL_LINEA = 1;
  COL_ARTICULO = 2;
  COL_SKU = 3;
  COL_ALMACEN = 4;
  COL_DESCRIPCION_ART = 5;
  COL_MODELO = 6;
  COL_FAMILIA = 7;
  COL_PROVEEDOR = 8;
  COL_TEMPORADA = 9;
  COL_TARIFA = 10;
  COL_PRECIO_TARIFA = 11;
  COL_DESCRIPCION_SKU = 12;
  COL_STOCK = 13;
  COL_CANTIDAD = 14;
  COL_ORIGEN = 15;
  COL_INSTANTE_STOCK = 16;
  COL_MAX = COL_INSTANTE_STOCK;

constructor TExportadorDocumentoTrabajo.Create(AControl: TdxSpreadSheet;
  const ACabecera, ALineas: TDataSet; AFotos: TFotosArticulos);
begin
  inherited Create;
  FControl := AControl;
  FCabecera := ACabecera;
  FLineas := ALineas;
  FFotos := AFotos;
end;

function TExportadorDocumentoTrabajo.TextoCodigoNombre(
  const ACodigo, ANombre: string): string;
begin
  Result := Trim(ACodigo);
  if Trim(ANombre) <> '' then
  begin
    if Result <> '' then
      Result := Result + ' - ';
    Result := Result + Trim(ANombre);
  end;
end;

procedure TExportadorDocumentoTrabajo.EscribirFecha(
  AFila, AColumna: Integer; ACampo: TField);
begin
  if (ACampo <> nil) and (not ACampo.IsNull) then
  begin
    W(FHoja, AFila, AColumna, ACampo.AsDateTime);
    FHoja.Cells[AFila, AColumna].Style.DataFormat.FormatCode :=
      'dd/mm/yyyy hh:mm';
  end;
end;

procedure TExportadorDocumentoTrabajo.IncrustarFoto(AFila: Integer;
  const ACodArt, ACodSku: string);
var
  oInfo: TFotoInfo;
  sClave: string;
  sRuta: string;
  oImagen: TdxSmartImage;
  oFoto: TdxSpreadSheetPictureContainer;
  oCelda: TdxSpreadSheetCell;
  iAncho: Integer;
  iAlto: Integer;
  iIzquierda: Integer;
  iArriba: Integer;
begin
  oInfo := Default(TFotoInfo);
  sClave := ACodArt + #1 + ACodSku;
  if Assigned(FFotos) and
     (not FFotosLinea.TryGetValue(sClave, oInfo)) then
  begin
    oInfo := FFotos.Resolver(ACodArt, ACodSku);
    FFotosLinea.Add(sClave, oInfo);
  end;
  sRuta := '';
  if Assigned(FFotos) then
    sRuta := FFotos.RutaFoto(oInfo, frPx300);
  if (sRuta <> '') and FileExists(sRuta) then
  begin
    oImagen := TdxSmartImage.Create;
    try
      oImagen.LoadFromFile(sRuta);
      FHoja.Rows[AFila].Size := cTamanoFoto;
      iAncho := oImagen.Width;
      iAlto := oImagen.Height;
      if (iAncho > cTamanoFoto) or (iAlto > cTamanoFoto) then
      begin
        if iAncho >= iAlto then
        begin
          iAlto := Round(iAlto * cTamanoFoto / iAncho);
          iAncho := cTamanoFoto;
        end
        else
        begin
          iAncho := Round(iAncho * cTamanoFoto / iAlto);
          iAlto := cTamanoFoto;
        end;
      end;
      iIzquierda := (cTamanoFoto - iAncho) div 2;
      iArriba := (cTamanoFoto - iAlto) div 2;
      oCelda := FHoja.CreateCell(AFila, COL_FOTO);
      oFoto := FHoja.Containers.Add(TdxSpreadSheetPictureContainer)
        as TdxSpreadSheetPictureContainer;
      oFoto.Picture.Image := oImagen;
      oFoto.RelativeResize := True;
      oFoto.AnchorType := catOneCell;
      oFoto.AnchorPoint1.Cell := oCelda;
      oFoto.AnchorPoint1.Offset := Point(iIzquierda, iArriba);
      oFoto.AnchorPoint2.Cell := oCelda;
      oFoto.AnchorPoint2.Offset := Point(iIzquierda + iAncho,
                                        iArriba + iAlto);
    finally
      FreeAndNil(oImagen);
    end;
  end
  else
    W(FHoja, AFila, COL_FOTO, 'Sin foto', False, ssahCenter);
end;

procedure TExportadorDocumentoTrabajo.EscribirCabeceraDocumento;
begin
  FFila := 1;
  W(FHoja, FFila, 0, 'DOCUMENTO DE TRABAJO', True);
  FHoja.Cells[FFila, 0].Style.Font.Size := 16;
  Merge(FHoja, FFila, 0, COL_MAX + 1, 1);
  Inc(FFila, 2);
  W(FHoja, FFila, 0, 'ID:', True);
  W(FHoja, FFila, 1, FCabecera.FieldByName(fidDtr).AsLargeInt);
  W(FHoja, FFila, 3, 'Título:', True);
  W(FHoja, FFila, 4, FCabecera.FieldByName(ftituloDtr).AsString);
  Merge(FHoja, FFila, 4, 4, 1);
  Inc(FFila);
  W(FHoja, FFila, 0, 'Tipo:', True);
  W(FHoja, FFila, 1, FCabecera.FieldByName(ftipoDtr).AsString);
  W(FHoja, FFila, 3, 'Estado:', True);
  W(FHoja, FFila, 4, FCabecera.FieldByName(festadoDtr).AsString);
  W(FHoja, FFila, 6, 'Propietario:', True);
  W(FHoja, FFila, 7, FCabecera.FieldByName(fusuarioDtr).AsString);
  Inc(FFila);
  W(FHoja, FFila, 0, 'Empresa:', True);
  W(FHoja, FFila, 1, FCabecera.FieldByName(fcodEmpDtr).AsString);
  W(FHoja, FFila, 3, 'Almacén:', True);
  W(FHoja, FFila, 4, FCabecera.FieldByName(fcodAlmDtr).AsString);
  W(FHoja, FFila, 6, 'Fecha:', True);
  EscribirFecha(FFila, 7, FCabecera.FindField(finstanteDtr));
  Inc(FFila, 2);
end;

procedure TExportadorDocumentoTrabajo.EscribirCabeceraLineas;
var
  iColumna: Integer;
begin
  W(FHoja, FFila, COL_FOTO,
    Format('Foto %d x %d', [cTamanoFoto, cTamanoFoto]),
    True, ssahCenter);
  W(FHoja, FFila, COL_LINEA, 'Línea', True, ssahCenter);
  W(FHoja, FFila, COL_ARTICULO, 'Artículo', True, ssahCenter);
  W(FHoja, FFila, COL_SKU, 'SKU', True, ssahCenter);
  W(FHoja, FFila, COL_ALMACEN, 'Almacén', True, ssahCenter);
  W(FHoja, FFila, COL_DESCRIPCION_ART, 'Descripción artículo',
    True, ssahCenter);
  W(FHoja, FFila, COL_MODELO, 'Modelo', True, ssahCenter);
  W(FHoja, FFila, COL_FAMILIA, 'Familia', True, ssahCenter);
  W(FHoja, FFila, COL_PROVEEDOR, 'Proveedor', True, ssahCenter);
  W(FHoja, FFila, COL_TEMPORADA, 'Temporada', True, ssahCenter);
  W(FHoja, FFila, COL_TARIFA, 'Tarifa', True, ssahCenter);
  W(FHoja, FFila, COL_PRECIO_TARIFA, 'Precio tarifa', True, ssahRight);
  W(FHoja, FFila, COL_DESCRIPCION_SKU, 'Descripción unidad',
    True, ssahCenter);
  W(FHoja, FFila, COL_STOCK, 'Stock', True, ssahRight);
  W(FHoja, FFila, COL_CANTIDAD, 'Cantidad', True, ssahRight);
  W(FHoja, FFila, COL_ORIGEN, 'Origen', True, ssahCenter);
  W(FHoja, FFila, COL_INSTANTE_STOCK, 'Instante stock',
    True, ssahCenter);
  for iColumna := 0 to COL_MAX do
  begin
    FHoja.Cells[FFila, iColumna].Style.Font.Color := clWhite;
    FHoja.Cells[FFila, iColumna].Style.Brush.BackgroundColor :=
      cColorCabecera;
    FHoja.Cells[FFila, iColumna].Style.Borders[bBottom].Style :=
      sscbsThin;
  end;
end;

procedure TExportadorDocumentoTrabajo.EscribirLinea;
begin
  FHoja.CreateCell(FFila, COL_FOTO);
  IncrustarFoto(FFila,
                FLineas.FieldByName(fcodArtDtl).AsString,
                FLineas.FieldByName(fcodUnidadDtl).AsString);
  W(FHoja, FFila, COL_LINEA,
    FLineas.FieldByName(flineaDtl).AsString, False, ssahCenter);
  W(FHoja, FFila, COL_ARTICULO,
    FLineas.FieldByName(fcodArtDtl).AsString);
  W(FHoja, FFila, COL_SKU,
    FLineas.FieldByName(fcodUnidadDtl).AsString);
  W(FHoja, FFila, COL_ALMACEN,
    FLineas.FieldByName(fcodAlmDtl).AsString);
  W(FHoja, FFila, COL_DESCRIPCION_ART,
    FLineas.FieldByName(fdescripcionArtDtl).AsString);
  if FLineas.FindField(frefProveedor) <> nil then
    W(FHoja, FFila, COL_MODELO,
      FLineas.FieldByName(frefProveedor).AsString);
  W(FHoja, FFila, COL_FAMILIA,
    TextoCodigoNombre(FLineas.FieldByName(fcodFamilia).AsString,
      FLineas.FieldByName(ffamilia).AsString));
  W(FHoja, FFila, COL_PROVEEDOR,
    TextoCodigoNombre(FLineas.FieldByName(fcodProveedor).AsString,
      FLineas.FieldByName(fproveedor).AsString));
  W(FHoja, FFila, COL_TEMPORADA,
    FLineas.FieldByName(ftemporada).AsString);
  W(FHoja, FFila, COL_TARIFA,
    TextoCodigoNombre(FLineas.FieldByName(fcodTarifa).AsString,
      FLineas.FieldByName(ftarifa).AsString));
  W(FHoja, FFila, COL_PRECIO_TARIFA,
    FLineas.FieldByName(fprecioTarifa).AsFloat, False, ssahRight);
  FHoja.Cells[FFila, COL_PRECIO_TARIFA].Style.DataFormat.FormatCode :=
    cFormatoPrecio;
  W(FHoja, FFila, COL_DESCRIPCION_SKU,
    FLineas.FieldByName(fdescripcionUnidadDtl).AsString);
  W(FHoja, FFila, COL_STOCK,
    FLineas.FieldByName(fcantidadStockDtl).AsFloat, False, ssahRight);
  FHoja.Cells[FFila, COL_STOCK].Style.DataFormat.FormatCode :=
    cFormatoCantidad;
  W(FHoja, FFila, COL_CANTIDAD,
    FLineas.FieldByName(fcantidadDtl).AsFloat, False, ssahRight);
  FHoja.Cells[FFila, COL_CANTIDAD].Style.DataFormat.FormatCode :=
    cFormatoCantidad;
  W(FHoja, FFila, COL_ORIGEN,
    FLineas.FieldByName(forigenDtl).AsString, False, ssahCenter);
  EscribirFecha(FFila, COL_INSTANTE_STOCK,
                FLineas.FindField(finstanteStockDtl));
end;

procedure TExportadorDocumentoTrabajo.ProcesarLineas;
var
  oMarcador: TBookmark;
begin
  if (FLineas <> nil) and FLineas.Active and (not FLineas.IsEmpty) then
  begin
    oMarcador := FLineas.GetBookmark;
    FLineas.DisableControls;
    try
      FLineas.First;
      while not FLineas.Eof do
      begin
        EscribirLinea;
        Inc(FFila);
        FLineas.Next;
      end;
    finally
      if FLineas.BookmarkValid(oMarcador) then
        FLineas.GotoBookmark(oMarcador);
      FLineas.FreeBookmark(oMarcador);
      FLineas.EnableControls;
    end;
  end;
end;

procedure TExportadorDocumentoTrabajo.ConfigurarAnchos;
begin
  FHoja.Columns[COL_FOTO].Size := cTamanoFoto;
  FHoja.Columns[COL_LINEA].Size := 55;
  FHoja.Columns[COL_ARTICULO].Size := 110;
  FHoja.Columns[COL_SKU].Size := 170;
  FHoja.Columns[COL_ALMACEN].Size := 80;
  FHoja.Columns[COL_DESCRIPCION_ART].Size := 220;
  FHoja.Columns[COL_MODELO].Size := 120;
  FHoja.Columns[COL_FAMILIA].Size := 160;
  FHoja.Columns[COL_PROVEEDOR].Size := 180;
  FHoja.Columns[COL_TEMPORADA].Size := 110;
  FHoja.Columns[COL_TARIFA].Size := 120;
  FHoja.Columns[COL_PRECIO_TARIFA].Size := 90;
  FHoja.Columns[COL_DESCRIPCION_SKU].Size := 180;
  FHoja.Columns[COL_STOCK].Size := 75;
  FHoja.Columns[COL_CANTIDAD].Size := 80;
  FHoja.Columns[COL_ORIGEN].Size := 80;
  FHoja.Columns[COL_INSTANTE_STOCK].Size := 125;
end;

procedure TExportadorDocumentoTrabajo.Ejecutar;
begin
  FControl.ClearAll;
  FHoja := FControl.AddSheet('Documento de trabajo',
    TdxSpreadSheetTableView) as TdxSpreadSheetTableView;
  FFotosLinea := TDictionary<string, TFotoInfo>.Create;
  FHoja.BeginUpdate;
  try
    EscribirCabeceraDocumento;
    EscribirCabeceraLineas;
    Inc(FFila);
    ProcesarLineas;
    ConfigurarAnchos;
  finally
    FHoja.EndUpdate;
    FreeAndNil(FFotosLinea);
  end;
end;

procedure ExportarDocumentoTrabajoExcel(
  ASheetControl: TdxSpreadSheet;
  const QCabecera, QLineas: TDataSet;
  AFotos: TFotosArticulos);
var
  oExportador: TExportadorDocumentoTrabajo;
begin
  oExportador := TExportadorDocumentoTrabajo.Create(
    ASheetControl, QCabecera, QLineas, AFotos);
  try
    oExportador.Ejecutar;
  finally
    FreeAndNil(oExportador);
  end;
end;

end.
