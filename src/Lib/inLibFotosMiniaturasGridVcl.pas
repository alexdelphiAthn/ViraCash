{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFotosMiniaturasGridVcl                                   }
{    Tipo:       Presentador VCL                                               }
{ Versión:       1.1.0                                                         }
{   Fecha:       18/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Columna de rejilla que pinta la tira de miniaturas (fotos a 300 px) de    }
{    la fila. Quien la usa decide de qué artículos salen las fotos: la tira    }
{    recibe una función que, dado el registro, devuelve artículo y SKU.        }
{    Recibe la vista y el servicio de fotos; nunca el formulario.              }
{******************************************************************************}
unit inLibFotosMiniaturasGridVcl;

interface

uses
  System.Classes, System.Generics.Collections, System.Types,
  System.UITypes,
  Vcl.Graphics, Vcl.Forms,
  cxGraphics, cxGridCustomTableView, cxGridCustomView,
  cxGridDBTableView, cxGridTableView,
  inLibFotos;

const
  // Medidas a 96 ppp: la clase las escala al PPI real de la rejilla.
  cLadoMiniaturaGrid    = 30;
  cMargenMiniaturaGrid  = 4;
  cHuecoMiniaturaGrid   = 4;
  cAnchoRestoMiniaturas = 24;
  cMaximoMiniaturasGrid = 3;
  // Lado de las fotos del desplegable (el "+N") y cuántas caben por fila.
  cLadoMiniaturaDesplegada  = 96;
  cColumnasMiniaturasDespl  = 5;
  // Tope de fotos que se leen por fila: una operación con cien líneas no
  // necesita cien rutas para pintar tres miniaturas y un "+N".
  cMaximoFotosPorFila = 40;
  // Topes de las cachés: al superarlos se vacían enteras (no hay LRU; el
  // coste de rehacerlas es una consulta por artículo).
  cMaximoCacheRutas      = 500;
  cMaximoCacheMiniaturas = 300;

type
  // Artículo (y SKU, si lo hay) del que salen fotos en una fila.
  TArticuloFotoFila = record
    Articulo: string;
    Sku: string;
    class function Crear(const AArticulo,
                               ASku: string): TArticuloFotoFila; static;
  end;

  TArticulosFotoFila = TArray<TArticuloFotoFila>;

  // Artículos cuyas fotos se pintan en la fila. AClave es la clave de
  // caché de esa fila (vacía = fila que no se cachea).
  TArticulosDeFilaFotos = reference to function(
    ARegistro: TcxCustomGridRecord;
    out AClave: string): TArticulosFotoFila;

  // Clave de cache de la fila, sin consultar nada. Existe para poder
  // mirar la cache antes de pedir los articulos: si no, cada repintado
  // acaba en la base de datos aunque la fila ya estuviera cacheada.
  TClaveDeFilaFotos = reference to function(
    ARegistro: TcxCustomGridRecord): string;

  // Añade a la vista una columna sin campo que dibuja hasta AMaximo
  // miniaturas por fila y un "+N" con las que no caben; al pulsar la
  // celda se despliegan todas en un cuadro flotante.
  //
  // El evento de dibujo se dispara en cada repintado, asi que ni consulta
  // la base de datos ni lee disco: cachea las rutas por fila y los bitmaps
  // ya escalados por ruta y lado. Se engancha al OnCustomDrawCell de su
  // propia columna, de modo que no pisa el evento de la vista; de la vista
  // sí toma OnGetCellHeight y OnCellClick, encadenando lo que hubiera.
  //
  // El alto de fila lo decide la propia tira: las filas con fotos crecen
  // hasta la miniatura y las que no tienen se quedan como estaban.
  TTiraMiniaturasFotosGrid = class
  private
    FVista         : TcxGridDBTableView;
    FColumna       : TcxGridDBColumn;
    FFotos         : TFotosArticulos;
    FArticulos     : TArticulosDeFilaFotos;
    FClave         : TClaveDeFilaFotos;
    FLado          : Integer;
    FMaximo        : Integer;
    FRutas         : TDictionary<string, TArray<string>>;
    FMiniaturas    : TObjectDictionary<string, Vcl.Graphics.TBitmap>;
    FDesplegado    : TForm;
    FAltoCeldaPrev : TcxGridGetCellHeightEvent;
    FClicCeldaPrev : TcxGridCellClickEvent;
    function Escalar(AValor96Ppp: Integer): Integer;
    function RutasDeRegistro(
      ARegistro: TcxCustomGridRecord): TArray<string>;
    function RutasDeArticulos(
      const AArticulos: TArticulosFotoFila): TArray<string>;
    procedure DibujarTira(ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo;
      const ARutas: TArray<string>;
      ALado: Integer);
    function Miniatura(const ARuta: string;
      ALado: Integer): Vcl.Graphics.TBitmap;
    procedure ConfigurarColumna(const ANombre, ATitulo: string);
    procedure EngancharEventosVista;
    procedure SoltarEventosVista;
    procedure DibujarCelda(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    procedure CalcularAltoCelda(Sender: TcxCustomGridTableView;
      ARecord: TcxCustomGridRecord;
      AItem: TcxCustomGridTableItem;
      ACellViewInfo: TcxGridTableDataCellViewInfo;
      var AHeight: Integer);
    procedure ClicEnCelda(Sender: TcxCustomGridTableView;
      ACellViewInfo: TcxGridTableDataCellViewInfo;
      AButton: TMouseButton;
      AShift: TShiftState;
      var AHandled: Boolean);
    procedure Desplegar(const ARutas: TArray<string>;
      const AZonaCelda: TRect);
    procedure AlCerrarDesplegado(Sender: TObject;
      var Action: TCloseAction);
    procedure CerrarDesplegado;
  public
    constructor Create(AVista: TcxGridDBTableView;
      AFotos: TFotosArticulos;
      const ANombre, ATitulo: string;
      AArticulos: TArticulosDeFilaFotos;
      AClave: TClaveDeFilaFotos = nil;
      ALado: Integer = cLadoMiniaturaGrid;
      AMaximo: Integer = cMaximoMiniaturasGrid);
    destructor Destroy; override;
    // Tira las cachés: se llama cuando se recarga la pantalla, para que una
    // foto añadida o rotada desde otro sitio se vea sin reabrir.
    procedure Limpiar;
    property Columna: TcxGridDBColumn read FColumna;
  end;

// Lee el PNG de ARuta y lo devuelve escalado con GDI+ (bicúbico) para que
// quepa en un cuadrado de ALado px, conservando la proporción y sobre fondo
// blanco. Lanza excepción si el fichero no se puede leer; el bitmap es del
// llamador.
function CrearMiniaturaFotoPng(const ARuta: string;
  ALado: Integer): Vcl.Graphics.TBitmap;

implementation

uses
  Winapi.Windows, Winapi.GDIPOBJ, Winapi.GDIPAPI,
  System.Math, System.SysUtils,
  Vcl.Controls, Vcl.Imaging.PngImage,
  inLibPosicionFormulario;

type
  // Cuadro flotante con todas las fotos de la fila: se abre al pulsar la
  // celda y se cierra al pulsar en él, con Esc o al perder el foco.
  TVentanaFotosFila = class(TForm)
  private
    FTira  : TTiraMiniaturasFotosGrid;
    FRutas : TArray<string>;
    FLado  : Integer;
    FMargen: Integer;
    FHueco : Integer;
    FColumnas: Integer;
    procedure AlDesactivar(Sender: TObject);
    procedure AlPulsarTecla(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure AlPulsarRaton(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  protected
    procedure Paint; override;
  public
    constructor CrearPara(ATira: TTiraMiniaturasFotosGrid;
      const ARutas: TArray<string>;
      ALado, AMargen, AHueco: Integer); reintroduce;
  end;

{ TArticuloFotoFila }

class function TArticuloFotoFila.Crear(
  const AArticulo, ASku: string): TArticuloFotoFila;
begin
  Result.Articulo := AArticulo;
  Result.Sku := ASku;
end;

{ TVentanaFotosFila }

constructor TVentanaFotosFila.CrearPara(ATira: TTiraMiniaturasFotosGrid;
  const ARutas: TArray<string>;
  ALado, AMargen, AHueco: Integer);
var
  iFilas: Integer;
begin
  inherited CreateNew(nil);
  FTira := ATira;
  FRutas := ARutas;
  FLado := ALado;
  FMargen := AMargen;
  FHueco := AHueco;
  FColumnas := Length(FRutas);
  if FColumnas > cColumnasMiniaturasDespl then
    FColumnas := cColumnasMiniaturasDespl;
  if FColumnas < 1 then
    FColumnas := 1;
  iFilas := Ceil(Length(FRutas) / FColumnas);
  BorderStyle := TFormBorderStyle.bsNone;
  // Pertenece al formulario de la rejilla: se dibuja sobre el sin
  // quedar por encima de las demas aplicaciones.
  AsociarVentanaPropietaria(Self, GetParentForm(ATira.FVista.Site));
  Position := poDesigned;
  Color := clWindow;
  KeyPreview := True;
  ClientWidth := 2 * FMargen + FColumnas * FLado +
    (FColumnas - 1) * FHueco;
  ClientHeight := 2 * FMargen + iFilas * FLado + (iFilas - 1) * FHueco;
  OnDeactivate := AlDesactivar;
  OnKeyDown := AlPulsarTecla;
  OnMouseDown := AlPulsarRaton;
end;

procedure TVentanaFotosFila.Paint;
var
  oMini : Vcl.Graphics.TBitmap;
  iFoto : Integer;
  iCol  : Integer;
  iFila : Integer;
  iIzq  : Integer;
  iTop  : Integer;
begin
  inherited;
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);
  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Color := clBtnShadow;
  Canvas.Rectangle(ClientRect);
  Canvas.Brush.Style := bsSolid;
  for iFoto := 0 to High(FRutas) do
  begin
    iCol := iFoto mod FColumnas;
    iFila := iFoto div FColumnas;
    iIzq := FMargen + iCol * (FLado + FHueco);
    iTop := FMargen + iFila * (FLado + FHueco);
    oMini := FTira.Miniatura(FRutas[iFoto], FLado);
    if Assigned(oMini) then
      Canvas.Draw(
        iIzq + (FLado - oMini.Width) div 2,
        iTop + (FLado - oMini.Height) div 2,
        oMini);
  end;
end;

procedure TVentanaFotosFila.AlDesactivar(Sender: TObject);
begin
  Close;
end;

procedure TVentanaFotosFila.AlPulsarTecla(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    Key := 0;
    Close;
  end;
end;

procedure TVentanaFotosFila.AlPulsarRaton(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  Close;
end;

{ TTiraMiniaturasFotosGrid }

constructor TTiraMiniaturasFotosGrid.Create(AVista: TcxGridDBTableView;
  AFotos: TFotosArticulos;
  const ANombre, ATitulo: string;
  AArticulos: TArticulosDeFilaFotos;
  AClave: TClaveDeFilaFotos;
  ALado: Integer;
  AMaximo: Integer);
begin
  inherited Create;
  FVista := AVista;
  FFotos := AFotos;
  FArticulos := AArticulos;
  FClave := AClave;
  FLado := ALado;
  FMaximo := AMaximo;
  if FMaximo < 1 then
    FMaximo := 1;
  FRutas := TDictionary<string, TArray<string>>.Create;
  FMiniaturas := TObjectDictionary<string, Vcl.Graphics.TBitmap>.Create(
    [doOwnsValues]);
  ConfigurarColumna(ANombre, ATitulo);
  EngancharEventosVista;
end;

destructor TTiraMiniaturasFotosGrid.Destroy;
begin
  CerrarDesplegado;
  // La columna pertenece a la vista y puede sobrevivir a este objeto: hay
  // que soltar los eventos antes de liberar las caches que usan.
  if Assigned(FColumna) then
    FColumna.OnCustomDrawCell := nil;
  SoltarEventosVista;
  FArticulos := nil;
  FClave := nil;
  FFotos := nil;
  FreeAndNil(FMiniaturas);
  FreeAndNil(FRutas);
  inherited Destroy;
end;

procedure TTiraMiniaturasFotosGrid.ConfigurarColumna(
  const ANombre, ATitulo: string);
begin
  FColumna := FVista.CreateColumn;
  if ANombre <> '' then
    FColumna.Name := ANombre;
  FColumna.Caption := ATitulo;
  // Columna sin campo: nada que ordenar, agrupar, filtrar ni editar (y la
  // exportacion a Excel la salta por no tener FieldName).
  FColumna.Options.Editing := False;
  FColumna.Options.Filtering := False;
  FColumna.Options.Grouping := False;
  FColumna.Options.Sorting := False;
  FColumna.HeaderAlignmentHorz := taCenter;
  FColumna.Width := Escalar(
    2 * cMargenMiniaturaGrid +
    FMaximo * FLado +
    (FMaximo - 1) * cHuecoMiniaturaGrid +
    cAnchoRestoMiniaturas);
  FColumna.OnCustomDrawCell := DibujarCelda;
end;

procedure TTiraMiniaturasFotosGrid.EngancharEventosVista;
begin
  // OnGetCellHeight y OnCellClick son de la vista, no de la columna: se
  // encadena lo que hubiera para no robarselo a nadie.
  FAltoCeldaPrev := FVista.OnGetCellHeight;
  FClicCeldaPrev := FVista.OnCellClick;
  FVista.OnGetCellHeight := CalcularAltoCelda;
  FVista.OnCellClick := ClicEnCelda;
end;

procedure TTiraMiniaturasFotosGrid.SoltarEventosVista;
begin
  if Assigned(FVista) then
  begin
    FVista.OnGetCellHeight := FAltoCeldaPrev;
    FVista.OnCellClick := FClicCeldaPrev;
  end;
  FAltoCeldaPrev := nil;
  FClicCeldaPrev := nil;
end;

function TTiraMiniaturasFotosGrid.Escalar(AValor96Ppp: Integer): Integer;
var
  iPpp: Integer;
begin
  iPpp := USER_DEFAULT_SCREEN_DPI;
  if (FVista <> nil) and (FVista.Site <> nil) then
    iPpp := FVista.Site.CurrentPPI;
  Result := MulDiv(AValor96Ppp, iPpp, USER_DEFAULT_SCREEN_DPI);
end;

procedure TTiraMiniaturasFotosGrid.Limpiar;
begin
  CerrarDesplegado;
  FMiniaturas.Clear;
  FRutas.Clear;
end;

// Rutas de las fotos de esos articulos, hasta el tope por fila.
function TTiraMiniaturasFotosGrid.RutasDeArticulos(
  const AArticulos: TArticulosFotoFila): TArray<string>;
var
  aFotos    : TArray<TFotoInfo>;
  sRuta     : string;
  iArticulo : Integer;
  iFoto     : Integer;
  iRutas    : Integer;
begin
  SetLength(Result, 0);
  iRutas := 0;
  try
    for iArticulo := 0 to High(AArticulos) do
    begin
      if iRutas >= cMaximoFotosPorFila then
        Break;
      aFotos := FFotos.ResolverColeccion(
        AArticulos[iArticulo].Articulo,
        AArticulos[iArticulo].Sku);
      SetLength(Result, iRutas + Length(aFotos));
      for iFoto := 0 to High(aFotos) do
      begin
        if iRutas >= cMaximoFotosPorFila then
          Break;
        sRuta := FFotos.RutaFoto(aFotos[iFoto], frPx300);
        if sRuta <> '' then
        begin
          Result[iRutas] := sRuta;
          Inc(iRutas);
        end;
      end;
    end;
  except
    // Un fallo de consulta no puede repetirse en cada repintado ni
    // tumbar la rejilla: la fila se queda sin fotos y se cachea asi.
    iRutas := 0;
  end;
  SetLength(Result, iRutas);
end;

function TTiraMiniaturasFotosGrid.RutasDeRegistro(
  ARegistro: TcxCustomGridRecord): TArray<string>;
var
  aArticulos : TArticulosFotoFila;
  sClave     : string;
  bEnCache   : Boolean;
begin
  SetLength(Result, 0);
  if Assigned(FFotos) and Assigned(FArticulos) and Assigned(ARegistro) then
  begin
    sClave := '';
    // Primero la cache: el dibujo y el alto de fila se recalculan en cada
    // repintado, y pedir los articulos cuesta una consulta por fila.
    bEnCache := False;
    if Assigned(FClave) then
    begin
      sClave := FClave(ARegistro);
      bEnCache := (sClave <> '') and FRutas.TryGetValue(sClave, Result);
    end;
    if not bEnCache then
    begin
      // Sin funcion de clave, la clave la devuelve quien da los
      // articulos, asi que la cache solo se puede mirar despues.
      aArticulos := FArticulos(ARegistro, sClave);
      bEnCache := (sClave <> '') and FRutas.TryGetValue(sClave, Result);
      if not bEnCache then
      begin
        Result := RutasDeArticulos(aArticulos);
        if sClave <> '' then
        begin
          if FRutas.Count >= cMaximoCacheRutas then
            FRutas.Clear;
          FRutas.AddOrSetValue(sClave, Result);
        end;
      end;
    end;
  end;
end;

function CrearMiniaturaFotoPng(const ARuta: string;
  ALado: Integer): Vcl.Graphics.TBitmap;
var
  oDestino   : Vcl.Graphics.TBitmap;
  oGdi       : TGPGraphics;
  oGdiOrigen : TGPBitmap;
  oOrigen    : Vcl.Graphics.TBitmap;
  oPng       : TPngImage;
  iAlto      : Integer;
  iAncho     : Integer;
begin
  oPng := TPngImage.Create;
  try
    oPng.LoadFromFile(ARuta);
    // Escalado conservando la proporcion dentro del cuadrado pedido.
    if oPng.Width >= oPng.Height then
    begin
      iAncho := ALado;
      iAlto := MulDiv(oPng.Height, ALado, oPng.Width);
    end
    else
    begin
      iAlto := ALado;
      iAncho := MulDiv(oPng.Width, ALado, oPng.Height);
    end;
    if iAncho < 1 then
      iAncho := 1;
    if iAlto < 1 then
      iAlto := 1;
    oOrigen := Vcl.Graphics.TBitmap.Create;
    oDestino := Vcl.Graphics.TBitmap.Create;
    try
      oOrigen.PixelFormat := pf32bit;
      oOrigen.SetSize(oPng.Width, oPng.Height);
      oOrigen.Canvas.Brush.Color := clWhite;
      oOrigen.Canvas.FillRect(
        Rect(0, 0, oPng.Width, oPng.Height));
      oOrigen.Canvas.Draw(0, 0, oPng);
      oDestino.PixelFormat := pf32bit;
      oDestino.SetSize(iAncho, iAlto);
      oDestino.Canvas.Brush.Color := clWhite;
      oDestino.Canvas.FillRect(Rect(0, 0, iAncho, iAlto));
      // GDI+ para el remuestreo: un StretchDraw de GDI deja escalones
      // muy visibles al bajar de 300 px a 40.
      oGdiOrigen := TGPBitmap.Create(oOrigen.Handle, 0);
      try
        oGdi := TGPGraphics.Create(oDestino.Canvas.Handle);
        try
          oGdi.SetInterpolationMode(
            InterpolationModeHighQualityBicubic);
          oGdi.SetPixelOffsetMode(PixelOffsetModeHighQuality);
          oGdi.SetSmoothingMode(SmoothingModeHighQuality);
          oGdi.DrawImage(oGdiOrigen, 0, 0, iAncho, iAlto);
        finally
          FreeAndNil(oGdi);
        end;
      finally
        FreeAndNil(oGdiOrigen);
      end;
      Result := oDestino;
      oDestino := nil;
    finally
      FreeAndNil(oOrigen);
      FreeAndNil(oDestino);
    end;
  finally
    FreeAndNil(oPng);
  end;
end;

function TTiraMiniaturasFotosGrid.Miniatura(const ARuta: string;
  ALado: Integer): Vcl.Graphics.TBitmap;
var
  sClave: string;
begin
  sClave := ARuta + '|' + IntToStr(ALado);
  if not FMiniaturas.TryGetValue(sClave, Result) then
  begin
    try
      Result := CrearMiniaturaFotoPng(ARuta, ALado);
    except
      // Una foto ilegible se cachea como nula: la celda la salta y no se
      // reintenta en cada repintado.
      Result := nil;
    end;
    FMiniaturas.Add(sClave, Result);
  end;
end;

procedure TTiraMiniaturasFotosGrid.CalcularAltoCelda(
  Sender: TcxCustomGridTableView;
  ARecord: TcxCustomGridRecord;
  AItem: TcxCustomGridTableItem;
  ACellViewInfo: TcxGridTableDataCellViewInfo;
  var AHeight: Integer);
var
  iAlto: Integer;
begin
  if Assigned(FAltoCeldaPrev) then
    FAltoCeldaPrev(Sender, ARecord, AItem, ACellViewInfo, AHeight);
  // Solo crecen las filas que tienen fotos; las demas se quedan con el
  // alto normal de la rejilla.
  if (AItem = FColumna) and
     (Length(RutasDeRegistro(ARecord)) > 0) then
  begin
    iAlto := Escalar(FLado + 2 * cMargenMiniaturaGrid);
    if AHeight < iAlto then
      AHeight := iAlto;
  end;
end;

procedure TTiraMiniaturasFotosGrid.DibujarCelda(
  Sender: TcxCustomGridTableView;
  ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo;
  var ADone: Boolean);
var
  aRutas   : TArray<string>;
  rCelda   : TRect;
  iLado    : Integer;
  iMargen  : Integer;
begin
  if (ACanvas <> nil) and (AViewInfo <> nil) and
     (AViewInfo.GridRecord <> nil) then
  begin
    rCelda := AViewInfo.Bounds;
    // Params.Color respeta seleccion y foco; a partir de aqui la celda la
    // pintamos nosotros entera (sin texto).
    ACanvas.FillRect(rCelda, AViewInfo.Params.Color);
    ADone := True;
    if FMiniaturas.Count >= cMaximoCacheMiniaturas then
      FMiniaturas.Clear;
    aRutas := RutasDeRegistro(AViewInfo.GridRecord);
    iMargen := Escalar(cMargenMiniaturaGrid);
    iLado := Escalar(FLado);
    // Si el usuario ha bajado el alto de fila, la miniatura se achica
    // con el.
    if iLado > rCelda.Height - 2 * iMargen then
      iLado := rCelda.Height - 2 * iMargen;
    if (Length(aRutas) > 0) and (iLado > 0) then
      DibujarTira(ACanvas, AViewInfo, aRutas, iLado);
  end;
end;

// Las miniaturas que caben, seguidas, y el "+N" con las que no.
procedure TTiraMiniaturasFotosGrid.DibujarTira(ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo;
  const ARutas: TArray<string>;
  ALado: Integer);
var
  oMini    : Vcl.Graphics.TBitmap;
  rCelda   : TRect;
  rResto   : TRect;
  sResto   : string;
  iCentro  : Integer;
  iHueco   : Integer;
  iIzq     : Integer;
  iMargen  : Integer;
  iMiniatura : Integer;
  iVisibles  : Integer;
begin
  rCelda := AViewInfo.Bounds;
  iMargen := Escalar(cMargenMiniaturaGrid);
  iHueco := Escalar(cHuecoMiniaturaGrid);
  iVisibles := Length(ARutas);
  if iVisibles > FMaximo then
    iVisibles := FMaximo;
  iIzq := rCelda.Left + iMargen;
  iCentro := (rCelda.Top + rCelda.Bottom) div 2;
  for iMiniatura := 0 to iVisibles - 1 do
  begin
    oMini := Miniatura(ARutas[iMiniatura], ALado);
    if Assigned(oMini) then
      ACanvas.Canvas.Draw(
        iIzq + (ALado - oMini.Width) div 2,
        iCentro - oMini.Height div 2,
        oMini);
    Inc(iIzq, ALado + iHueco);
  end;
  if Length(ARutas) > iVisibles then
  begin
    sResto := '+' + IntToStr(Length(ARutas) - iVisibles);
    rResto := Rect(iIzq, rCelda.Top, rCelda.Right - iMargen,
      rCelda.Bottom);
    ACanvas.Font.Assign(AViewInfo.Params.Font);
    ACanvas.Font.Color := AViewInfo.Params.TextColor;
    ACanvas.Brush.Style := bsClear;
    // TcxCanvas.DrawText lleva banderas cx*, no DT_* de Windows.
    ACanvas.DrawText(sResto, rResto,
      cxSingleLine or cxAlignVCenter or cxAlignLeft);
    ACanvas.Brush.Style := bsSolid;
  end;
end;

procedure TTiraMiniaturasFotosGrid.ClicEnCelda(
  Sender: TcxCustomGridTableView;
  ACellViewInfo: TcxGridTableDataCellViewInfo;
  AButton: TMouseButton;
  AShift: TShiftState;
  var AHandled: Boolean);
var
  aRutas: TArray<string>;
begin
  if Assigned(FClicCeldaPrev) then
    FClicCeldaPrev(Sender, ACellViewInfo, AButton, AShift, AHandled);
  if (not AHandled) and (AButton = mbLeft) and (ACellViewInfo <> nil) and
     (ACellViewInfo.Item = FColumna) then
  begin
    aRutas := RutasDeRegistro(ACellViewInfo.GridRecord);
    // El desplegable solo tiene sentido si hay fotos que no se ven.
    // El clic no se consume: el grid sigue llevando el foco a esa fila.
    if Length(aRutas) > FMaximo then
      Desplegar(aRutas, ACellViewInfo.Bounds);
  end;
end;

procedure TTiraMiniaturasFotosGrid.Desplegar(const ARutas: TArray<string>;
  const AZonaCelda: TRect);
var
  oVentana : TVentanaFotosFila;
  rPantalla: TRect;
  pOrigen  : TPoint;
begin
  CerrarDesplegado;
  if (FVista <> nil) and (FVista.Site <> nil) then
  begin
    oVentana := TVentanaFotosFila.CrearPara(
      Self,
      ARutas,
      Escalar(cLadoMiniaturaDesplegada),
      Escalar(cMargenMiniaturaGrid) * 2,
      Escalar(cHuecoMiniaturaGrid));
    FDesplegado := oVentana;
    // Debajo de la celda, y si no cabe, encima; siempre dentro del
    // monitor.
    pOrigen := FVista.Site.ClientToScreen(
      Point(AZonaCelda.Left, AZonaCelda.Bottom));
    rPantalla := Screen.MonitorFromPoint(pOrigen).WorkareaRect;
    if pOrigen.Y + oVentana.Height > rPantalla.Bottom then
      pOrigen.Y := FVista.Site.ClientToScreen(
        Point(AZonaCelda.Left, AZonaCelda.Top)).Y - oVentana.Height;
    if pOrigen.Y < rPantalla.Top then
      pOrigen.Y := rPantalla.Top;
    if pOrigen.X + oVentana.Width > rPantalla.Right then
      pOrigen.X := rPantalla.Right - oVentana.Width;
    if pOrigen.X < rPantalla.Left then
      pOrigen.X := rPantalla.Left;
    oVentana.OnClose := AlCerrarDesplegado;
    oVentana.Left := pOrigen.X;
    oVentana.Top := pOrigen.Y;
    oVentana.Show;
  end;
end;

procedure TTiraMiniaturasFotosGrid.AlCerrarDesplegado(Sender: TObject;
  var Action: TCloseAction);
begin
  // Se cierra solo (clic, Esc o perder el foco): que se libere el, no
  // nosotros, y que el puntero no quede colgando.
  Action := caFree;
  if FDesplegado = Sender then
    FDesplegado := nil;
end;

procedure TTiraMiniaturasFotosGrid.CerrarDesplegado;
begin
  if Assigned(FDesplegado) then
  begin
    FDesplegado.OnClose := nil;
    FreeAndNil(FDesplegado);
  end;
end;

end.
