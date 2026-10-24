{******************************************************************************}
{                                                                              }
{  Módulo:       inLibHojaCalculoDevEx                                         }
{    Tipo:       Librería (adaptador)                                          }
{ Versión:       2.0.0                                                         }
{   Fecha:       25/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptadores de hoja de cálculo sobre DevExpress (TdxSpreadSheet).         }
{    ÚNICA unidad del subsistema que ve tipos Tdx*. Las 4 operaciones de       }
{    bajo nivel (mezclar, escribir, fórmula, cuadro) son métodos de clase      }
{    (fuente única): las usan tanto el puerto como los shims de inLibDevExcel. }
{    v1.1 (Fase 2): añade formato, fondo, borde por lado, tamaño de fuente,    }
{    negrita, ancho de columna, lote y existencia de celda.                    }
{******************************************************************************}
unit inLibHojaCalculoDevEx;

interface

uses
  dxSpreadSheet, dxSpreadSheetCore, Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, cxGraphics,
  System.Classes, System.Generics.Collections, Vcl.Graphics, System.Types,
  dxSpreadSheetTypes, dxSpreadSheetGraphics, dxCoreGraphics, dxShellDialogs,
  dxSpreadSheetStyles, dxSpreadSheetCoreStyles, dxHashUtils,
  inLibHojaCalculoIntf;

type
  EHojaCalculo = class(Exception);
  // Adaptador DevExpress del puerto de escritura. Envuelve un control
  // TdxSpreadSheet (o una vista de tabla suelta para los shims legacy).
  TEscritorHojaCalculoDevEx = class(
    TInterfacedObject,
    IEscritorHojaCalculo,
    IEscritorHojaCalculoConFormato,
    IFormateadorHojaCalculo,
    IGuardadorHojaCalculo,
    ILectorHojaCalculo,
    IImagenesHojaCalculo)
  private
    FControl: TdxSpreadSheet;
    FEstilosEscritura:
      TDictionary<string, TdxSpreadSheetCellStyleHandle>;
    FTabla: TdxSpreadSheetTableView;
    function ClaveEstiloEscritura(ANegrita: Boolean;
      AAlineacion: TAlineacionCelda; const AFormato: string): string;
    procedure LimpiarEstilosEscritura;
    function MapAlineacion(
      AAlineacion: TAlineacionCelda): TdxSpreadSheetDataAlignHorz;
    function MapBorde(AEstilo: TEstiloBorde): TdxSpreadSheetCellBorderStyle;
    procedure AsegurarTabla;
  public
    constructor Create(const AControl: TdxSpreadSheet);
    constructor CreateTabla(const ATabla: TdxSpreadSheetTableView);
    destructor Destroy; override;
    // Operaciones dx de bajo nivel (fuente única). Reciben tipos dx tal cual
    // para que los shims de inLibDevExcel deleguen sin mapeo inverso.
    class procedure MezclarDx(const ATabla: TdxSpreadSheetTableView;
      AFila, ACol, AColCount, AFilaCount: Integer); static;
    class procedure EscribirCeldaDx(const ATabla: TdxSpreadSheetTableView;
      AFila, ACol: Integer; const AValor: Variant; ANegrita: Boolean;
      ADxAlineacion: TdxSpreadSheetDataAlignHorz); static;
    class procedure EscribirFormulaDx(const ATabla: TdxSpreadSheetTableView;
      AFila, ACol: Integer; const AFormula, AFormato: string); static;
    class procedure PintarCuadroDx(const ATabla: TdxSpreadSheetTableView;
      AF1, AC1, AF2, AC2: Integer;
      ADxEstilo: TdxSpreadSheetCellBorderStyle); static;
    // IEscritorHojaCalculo
    procedure NuevaHoja(const ANombre: string);
    procedure IniciarLote;
    procedure FinalizarLote;
    procedure Escribir(AFila, ACol: Integer; const AValor: Variant);
    procedure EscribirFormula(
      AFila, ACol: Integer;
      const AFormula: string);
    procedure Combinar(AFila, ACol, ANumFilas, ANumCols: Integer);
    function CeldaExiste(AFila, ACol: Integer): Boolean;
    // IEscritorHojaCalculoConFormato
    procedure EscribirConFormato(
      AFila, ACol: Integer;
      const AValor: Variant;
      ANegrita: Boolean;
      AAlineacion: TAlineacionCelda;
      const AFormato: string);
    // IFormateadorHojaCalculo
    procedure DibujarCuadro(AF1, AC1, AF2, AC2: Integer;
      AEstilo: TEstiloBorde);
    procedure BordeCelda(AFila, ACol: Integer; ALado: TLadoBorde;
      AEstilo: TEstiloBorde);
    procedure FondoCelda(AFila, ACol: Integer; AColor: Cardinal);
    procedure Negrita(AFila, ACol: Integer; AActivar: Boolean = True);
    procedure TamanoFuente(AFila, ACol: Integer; ATamano: Integer);
    procedure AnchoColumna(ACol: Integer; AAncho: Integer);
    procedure Alinear(
      AFila, ACol: Integer;
      AAlineacion: TAlineacionCelda);
    procedure AplicarFormato(
      AFila, ACol: Integer;
      const AFormato: string);
    // IGuardadorHojaCalculo
    procedure Guardar(const ARuta: string);
    // IImagenesHojaCalculo
    function InsertarImagen(AFila, ACol: Integer; const ARuta: string;
      AAnchoMaximo, AAltoMaximo: Integer): Boolean;
    // ILectorHojaCalculo
    function LeerCelda(AFila, ACol: Integer): Variant;
    function LeerFormatoCelda(AFila, ACol: Integer): string;
    function UltimaFila: Integer;
    function UltimaColumna: Integer;
  end;

// Servicios ligados al control.
function CrearServiciosHojaCalculoDevEx(
  const AControl: TdxSpreadSheet): TServiciosHojaCalculo;
// Servicios sobre una vista suelta. Guardador queda sin asignar.
function CrearServiciosHojaCalculoDevExTabla(
  const ATabla: TdxSpreadSheetTableView): TServiciosHojaCalculo;
// Lector sobre la primera hoja de un control ya cargado (sin limpiarlo).
function CrearLectorDevEx(
  const AControl: TdxSpreadSheet): ILectorHojaCalculo;

implementation

uses
  System.Math, dxSpreadSheetContainers, dxGDIPlusClasses, inLibMsgComun;

const
  // Margen vertical de la fila alrededor de una imagen incrustada.
  MARGEN_FILA_IMAGEN = 4;

class procedure TEscritorHojaCalculoDevEx.MezclarDx(
  const ATabla: TdxSpreadSheetTableView;
  AFila, ACol, AColCount, AFilaCount: Integer);
var
  R: TRect;
begin
  // TRect(Left, Top, Right, Bottom) con la esquina final inclusive.
  R.Left := ACol;
  R.Top := AFila;
  R.Right := ACol + AColCount - 1;
  R.Bottom := AFila + AFilaCount - 1;
  ATabla.MergedCells.Add(R);
end;

class procedure TEscritorHojaCalculoDevEx.EscribirCeldaDx(
  const ATabla: TdxSpreadSheetTableView; AFila, ACol: Integer;
  const AValor: Variant; ANegrita: Boolean;
  ADxAlineacion: TdxSpreadSheetDataAlignHorz);
var
  Celda: TdxSpreadSheetCell;
begin
  Celda := ATabla.CreateCell(AFila, ACol);
  Celda.AsVariant := AValor;
  if ANegrita then
    Celda.Style.Font.Style := [fsBold]
  else
    Celda.Style.Font.Style := [];
  Celda.Style.AlignHorz := ADxAlineacion;
  Celda.Style.AlignVert := ssavCenter;
end;

class procedure TEscritorHojaCalculoDevEx.EscribirFormulaDx(
  const ATabla: TdxSpreadSheetTableView; AFila, ACol: Integer;
  const AFormula, AFormato: string);
var
  Celda: TdxSpreadSheetCell;
begin
  Celda := ATabla.CreateCell(AFila, ACol);
  // SetText(..., True) es crítico para que interprete la fórmula.
  Celda.SetText(AFormula, True);
  Celda.Style.AlignHorz := ssahRight;
  if AFormato <> '' then
    Celda.Style.DataFormat.FormatCode := AFormato;
end;

class procedure TEscritorHojaCalculoDevEx.PintarCuadroDx(
  const ATabla: TdxSpreadSheetTableView; AF1, AC1, AF2, AC2: Integer;
  ADxEstilo: TdxSpreadSheetCellBorderStyle);
var
  iFila, iCol: Integer;
begin
  // Techo y suelo del cuadro.
  for iCol := AC1 to AC2 do
  begin
    if ATabla.Cells[AF1, iCol] = nil then
      ATabla.CreateCell(AF1, iCol);
    ATabla.Cells[AF1, iCol].Style.Borders[bTop].Style := ADxEstilo;
    if ATabla.Cells[AF2, iCol] = nil then
      ATabla.CreateCell(AF2, iCol);
    ATabla.Cells[AF2, iCol].Style.Borders[bBottom].Style := ADxEstilo;
  end;
  // Paredes izquierda y derecha.
  for iFila := AF1 to AF2 do
  begin
    if ATabla.Cells[iFila, AC1] = nil then
      ATabla.CreateCell(iFila, AC1);
    ATabla.Cells[iFila, AC1].Style.Borders[bLeft].Style := ADxEstilo;
    if ATabla.Cells[iFila, AC2] = nil then
      ATabla.CreateCell(iFila, AC2);
    ATabla.Cells[iFila, AC2].Style.Borders[bRight].Style := ADxEstilo;
  end;
end;

constructor TEscritorHojaCalculoDevEx.Create(const AControl: TdxSpreadSheet);
begin
  inherited Create;
  FControl := AControl;
  FEstilosEscritura :=
    TDictionary<string, TdxSpreadSheetCellStyleHandle>.Create;
  // La hoja se crea al llamar a NuevaHoja (patrón de los exportadores).
  FTabla := nil;
end;

constructor TEscritorHojaCalculoDevEx.CreateTabla(
  const ATabla: TdxSpreadSheetTableView);
begin
  inherited Create;
  FControl := nil;
  FEstilosEscritura :=
    TDictionary<string, TdxSpreadSheetCellStyleHandle>.Create;
  FTabla := ATabla;
end;

destructor TEscritorHojaCalculoDevEx.Destroy;
begin
  LimpiarEstilosEscritura;
  FreeAndNil(FEstilosEscritura);
  inherited Destroy;
end;

function TEscritorHojaCalculoDevEx.ClaveEstiloEscritura(
  ANegrita: Boolean; AAlineacion: TAlineacionCelda;
  const AFormato: string): string;
begin
  Result := IntToStr(Ord(ANegrita)) + ':' +
    IntToStr(Ord(AAlineacion)) + ':' + AFormato;
end;

procedure TEscritorHojaCalculoDevEx.LimpiarEstilosEscritura;
var
  oEstilo: TdxSpreadSheetCellStyleHandle;
begin
  if FEstilosEscritura <> nil then
  begin
    for oEstilo in FEstilosEscritura.Values do
      oEstilo.Release;
    FEstilosEscritura.Clear;
  end;
end;

function TEscritorHojaCalculoDevEx.MapAlineacion(
  AAlineacion: TAlineacionCelda): TdxSpreadSheetDataAlignHorz;
begin
  case AAlineacion of
    acCentro:
      Result := ssahCenter;
    acDerecha:
      Result := ssahRight;
  else
    Result := ssahLeft;
  end;
end;

function TEscritorHojaCalculoDevEx.MapBorde(
  AEstilo: TEstiloBorde): TdxSpreadSheetCellBorderStyle;
begin
  case AEstilo of
    ebFino:
      Result := sscbsThin;
    ebMedio:
      Result := sscbsMedium;
    ebGrueso:
      Result := sscbsThick;
  else
    Result := sscbsNone;
  end;
end;

procedure TEscritorHojaCalculoDevEx.AsegurarTabla;
begin
  if FTabla = nil then
    raise EHojaCalculo.Create(SErrorHojaCalculoNoActiva);
end;

procedure TEscritorHojaCalculoDevEx.NuevaHoja(const ANombre: string);
begin
  if FControl = nil then
    raise EHojaCalculo.Create(SErrorControlHojaCalculoObligatorio);
  LimpiarEstilosEscritura;
  FControl.ClearAll;
  FTabla := FControl.AddSheet(ANombre, TdxSpreadSheetTableView)
    as TdxSpreadSheetTableView;
end;

procedure TEscritorHojaCalculoDevEx.IniciarLote;
begin
  AsegurarTabla;
  FTabla.BeginUpdate;
end;

procedure TEscritorHojaCalculoDevEx.FinalizarLote;
begin
  AsegurarTabla;
  FTabla.EndUpdate;
end;

procedure TEscritorHojaCalculoDevEx.Escribir(
  AFila, ACol: Integer;
  const AValor: Variant);
begin
  AsegurarTabla;
  FTabla.CreateCell(AFila, ACol).AsVariant := AValor;
end;

procedure TEscritorHojaCalculoDevEx.EscribirConFormato(
  AFila, ACol: Integer;
  const AValor: Variant;
  ANegrita: Boolean;
  AAlineacion: TAlineacionCelda;
  const AFormato: string);
var
  oCelda: TdxSpreadSheetCell;
  oEstilo: TdxSpreadSheetCellStyle;
  oEstiloHandle: TdxSpreadSheetCellStyleHandle;
  sClaveEstilo: string;
begin
  AsegurarTabla;
  oCelda := FTabla.CreateCell(AFila, ACol);
  oCelda.AsVariant := AValor;
  sClaveEstilo := ClaveEstiloEscritura(
    ANegrita, AAlineacion, AFormato);
  oEstiloHandle := nil;
  if FEstilosEscritura.TryGetValue(sClaveEstilo, oEstiloHandle) then
    oCelda.StyleHandle := oEstiloHandle
  else
  begin
    oEstilo := oCelda.Style;
    oEstilo.BeginUpdate;
    try
      if ANegrita then
        oEstilo.Font.Style := [fsBold]
      else
        oEstilo.Font.Style := [];
      oEstilo.AlignHorz := MapAlineacion(AAlineacion);
      oEstilo.AlignVert := ssavCenter;
      if AFormato <> '' then
        oEstilo.DataFormat.FormatCode := AFormato;
    finally
      oEstilo.EndUpdate;
    end;
    oEstiloHandle := oCelda.StyleHandle;
    oEstiloHandle.AddRef;
    try
      FEstilosEscritura.Add(sClaveEstilo, oEstiloHandle);
    except
      oEstiloHandle.Release;
      raise;
    end;
  end;
end;

procedure TEscritorHojaCalculoDevEx.EscribirFormula(
  AFila, ACol: Integer;
  const AFormula: string);
begin
  AsegurarTabla;
  FTabla.CreateCell(AFila, ACol).SetText(AFormula, True);
end;

procedure TEscritorHojaCalculoDevEx.Combinar(AFila, ACol, ANumFilas,
  ANumCols: Integer);
begin
  AsegurarTabla;
  MezclarDx(FTabla, AFila, ACol, ANumCols, ANumFilas);
end;

procedure TEscritorHojaCalculoDevEx.DibujarCuadro(AF1, AC1, AF2,
  AC2: Integer; AEstilo: TEstiloBorde);
begin
  AsegurarTabla;
  PintarCuadroDx(FTabla, AF1, AC1, AF2, AC2, MapBorde(AEstilo));
end;

procedure TEscritorHojaCalculoDevEx.BordeCelda(AFila, ACol: Integer;
  ALado: TLadoBorde; AEstilo: TEstiloBorde);
var
  oBorde: TcxBorder;
begin
  AsegurarTabla;
  case ALado of
    lbSuperior:
      oBorde := bTop;
    lbInferior:
      oBorde := bBottom;
    lbIzquierdo:
      oBorde := bLeft;
  else
    oBorde := bRight;
  end;
  FTabla.CreateCell(AFila, ACol).Style.Borders[oBorde].Style :=
    MapBorde(AEstilo);
end;

procedure TEscritorHojaCalculoDevEx.FondoCelda(AFila, ACol: Integer;
  AColor: Cardinal);
begin
  AsegurarTabla;
  FTabla.CreateCell(AFila, ACol).Style.Brush.BackgroundColor :=
    TdxAlphaColor(AColor);
end;

procedure TEscritorHojaCalculoDevEx.Negrita(AFila, ACol: Integer;
  AActivar: Boolean);
begin
  AsegurarTabla;
  if AActivar then
    FTabla.CreateCell(AFila, ACol).Style.Font.Style := [fsBold]
  else
    FTabla.CreateCell(AFila, ACol).Style.Font.Style := [];
end;

procedure TEscritorHojaCalculoDevEx.TamanoFuente(AFila, ACol: Integer;
  ATamano: Integer);
begin
  AsegurarTabla;
  FTabla.CreateCell(AFila, ACol).Style.Font.Size := ATamano;
end;

procedure TEscritorHojaCalculoDevEx.AnchoColumna(ACol: Integer;
  AAncho: Integer);
begin
  AsegurarTabla;
  FTabla.Columns[ACol].Size := AAncho;
end;

procedure TEscritorHojaCalculoDevEx.Alinear(
  AFila, ACol: Integer;
  AAlineacion: TAlineacionCelda);
begin
  AsegurarTabla;
  FTabla.CreateCell(AFila, ACol).Style.AlignHorz :=
    MapAlineacion(AAlineacion);
  FTabla.Cells[AFila, ACol].Style.AlignVert := ssavCenter;
end;

procedure TEscritorHojaCalculoDevEx.AplicarFormato(
  AFila, ACol: Integer;
  const AFormato: string);
begin
  AsegurarTabla;
  FTabla.CreateCell(AFila, ACol).Style.DataFormat.FormatCode :=
    AFormato;
end;

function TEscritorHojaCalculoDevEx.CeldaExiste(AFila, ACol: Integer): Boolean;
begin
  AsegurarTabla;
  Result := FTabla.Cells[AFila, ACol] <> nil;
end;

procedure TEscritorHojaCalculoDevEx.Guardar(const ARuta: string);
begin
  if FControl = nil then
    raise EHojaCalculo.Create(
      SErrorGuardarHojaCalculoControlObligatorio);
  FControl.SaveToFile(ARuta);
end;

function TEscritorHojaCalculoDevEx.InsertarImagen(AFila, ACol: Integer;
  const ARuta: string; AAnchoMaximo, AAltoMaximo: Integer): Boolean;
var
  iAlto: Integer;
  iAncho: Integer;
  iArriba: Integer;
  iIzquierda: Integer;
  oCelda: TdxSpreadSheetCell;
  oFila: TdxSpreadSheetTableRow;
  oFoto: TdxSpreadSheetPictureContainer;
  oImagen: TdxSmartImage;
begin
  AsegurarTabla;
  Result := False;
  if (ARuta <> '') and FileExists(ARuta) then
  begin
    oImagen := TdxSmartImage.Create;
    try
      oImagen.LoadFromFile(ARuta);
      iAncho := oImagen.Width;
      iAlto := oImagen.Height;
      if (iAncho > 0) and (iAlto > 0) then
      begin
        if iAncho * AAltoMaximo >= iAlto * AAnchoMaximo then
        begin
          iAlto := Max(1, Round(iAlto * AAnchoMaximo / iAncho));
          iAncho := AAnchoMaximo;
        end
        else
        begin
          iAncho := Max(1, Round(iAncho * AAltoMaximo / iAlto));
          iAlto := AAltoMaximo;
        end;
        // Rows[] devuelve nil si la fila aún no tiene celdas (la foto se
        // incrusta antes que el texto): CreateItem la crea si falta.
        oFila := FTabla.Rows.CreateItem(AFila);
        if oFila.Size < AAltoMaximo + MARGEN_FILA_IMAGEN then
          oFila.Size := AAltoMaximo + MARGEN_FILA_IMAGEN;
        iIzquierda := (AAnchoMaximo - iAncho) div 2;
        iArriba := (AAltoMaximo + MARGEN_FILA_IMAGEN - iAlto) div 2;
        oCelda := FTabla.CreateCell(AFila, ACol);
        oFoto := FTabla.Containers.Add(TdxSpreadSheetPictureContainer)
          as TdxSpreadSheetPictureContainer;
        oFoto.Picture.Image := oImagen;
        oFoto.RelativeResize := True;
        oFoto.AnchorType := catOneCell;
        oFoto.AnchorPoint1.Cell := oCelda;
        oFoto.AnchorPoint1.Offset := Point(iIzquierda, iArriba);
        oFoto.AnchorPoint2.Cell := oCelda;
        oFoto.AnchorPoint2.Offset :=
          Point(iIzquierda + iAncho, iArriba + iAlto);
        Result := True;
      end;
    finally
      FreeAndNil(oImagen);
    end;
  end;
end;

function TEscritorHojaCalculoDevEx.LeerCelda(AFila, ACol: Integer): Variant;
begin
  Result := Null;
  if (FTabla <> nil) and (FTabla.Cells[AFila, ACol] <> nil) then
    Result := FTabla.Cells[AFila, ACol].AsVariant;
end;

function TEscritorHojaCalculoDevEx.LeerFormatoCelda(
  AFila, ACol: Integer): string;
begin
  Result := '';
  if (FTabla <> nil) and (FTabla.Cells[AFila, ACol] <> nil) then
    Result := FTabla.Cells[AFila, ACol].Style.DataFormat.FormatCode;
end;

function TEscritorHojaCalculoDevEx.UltimaFila: Integer;
begin
  if FTabla = nil then
    Result := -1
  else
    Result := FTabla.Dimensions.Bottom;
end;

function TEscritorHojaCalculoDevEx.UltimaColumna: Integer;
begin
  if FTabla = nil then
    Result := -1
  else
    Result := FTabla.Dimensions.Right;
end;

function CrearServiciosHojaCalculoDevEx(
  const AControl: TdxSpreadSheet): TServiciosHojaCalculo;
var
  oAdaptador: TEscritorHojaCalculoDevEx;
begin
  oAdaptador := TEscritorHojaCalculoDevEx.Create(AControl);
  Result.Escritor := oAdaptador;
  Result.Formateador := oAdaptador;
  Result.Guardador := oAdaptador;
end;

function CrearServiciosHojaCalculoDevExTabla(
  const ATabla: TdxSpreadSheetTableView): TServiciosHojaCalculo;
var
  oAdaptador: TEscritorHojaCalculoDevEx;
begin
  oAdaptador := TEscritorHojaCalculoDevEx.CreateTabla(ATabla);
  Result.Escritor := oAdaptador;
  Result.Formateador := oAdaptador;
  Result.Guardador := nil;
end;

function CrearLectorDevEx(
  const AControl: TdxSpreadSheet): ILectorHojaCalculo;
var
  oTabla: TdxSpreadSheetTableView;
begin
  oTabla := nil;
  if AControl.SheetCount > 0 then
    oTabla := AControl.Sheets[0] as TdxSpreadSheetTableView;
  Result := TEscritorHojaCalculoDevEx.CreateTabla(oTabla);
end;

end.
