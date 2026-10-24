{******************************************************************************}
{                                                                              }
{  Módulo:       inLibAtributosPaleta                                          }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       15/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Lookup de la paleta de atributos básicos (fza_atributos_basicos).         }
{    Cachea por (ID_VA_ATB, CODIGO_ATB) -> HEX_ATB + NOMBRE_ATB.               }
{    Expone helpers para pintar grids cxGrid (cuadrado / texto).               }
{******************************************************************************}
unit inLibAtributosPaleta;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  System.Types, System.Generics.Collections, Data.DB,
  Vcl.Graphics, Vcl.Controls, Vcl.ImgList,
  Uni,
  cxGraphics, cxEdit, cxDropDownEdit, cxLookupDBGrid,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView, System.UITypes,
  inLibAtributosPaletaIntf;

type
  TInfoBasico = inLibAtributosPaletaIntf.TInfoBasico;

const
  // Pixeles horizontales que reserva PintarCeldaConCuadradoColor delante
  // del texto para el swatch (margen + cuadrado + hueco). Se expone para
  // que los consumidores puedan ensanchar las columnas tras un ApplyBestFit
  // que solo mide el texto. Desglose: 24 geometrico (MARGEN_IZQ 4 +
  // LADO_CUADRADO 16 + HUECO_TEXTO 4) + holgura para que el texto no salga
  // pegado al cuadradito ni recortado (p.ej. "MARRON" en la columna Color).
  ANCHO_SWATCH_PX = 50;

// Invalida la cache (llamar al refrescar fza_atributos_basicos).
procedure InvalidarCachePaleta;
procedure ConfigurarLecturasAtributosPaleta(
  const ALecturas: ILecturasAtributosPaleta);
procedure ConfigurarSelectorAtributoPaleta(
  const ASelector: ISelectorAtributoPaleta);

// Busca por (ID_VA_ATB, CODIGO_ATB). Devuelve True si existe en la paleta
// Y su EXTRA_ATB es un color valido.
function ObtenerInfoBasico(AConexion: TUniConnection;
                           const AIdVA: string;
                           const ACodigoATB: string;
                           out AInfo: TInfoBasico): Boolean;

// Resuelve el basico asignado a un valor dentro de un articulo concreto.
// Es necesario para codigos de proveedor ambiguos como PALO.
function ObtenerInfoBasicoArticulo(AConexion: TUniConnection;
                                   const ACodArt, AIdVA, AValor: string;
                                   out AInfo: TInfoBasico): Boolean;

// Devuelve los codigos basicos de una variacion usados por los SKU activos
// de un articulo, ordenados como la paleta.
function ObtenerBasicosArticulo(AConexion: TUniConnection;
                                const ACodArt, AIdVA: string): TArray<string>;

// Convierte '#RRGGBB' o '#RGB' a TColor. Devuelve clNone si no parseable.
function HexToColor(const AHex: string): TColor;

// Pinta una celda cxGrid con un cuadrado de color delante del texto.
// Usar dentro de OnCustomDrawCell:
//   if PintarCeldaConCuadradoColor(ACanvas, AViewInfo, AInfo) then
//     ADone := True;
// El cuadrado se dibuja a la izquierda y el texto desplazado a la derecha.
// Si AViewInfo.Text esta vacio (caso TcxImageComboBox sin match en Items),
// se cae al valor crudo del campo via GridRecord.
function PintarCeldaConCuadradoColor(ACanvas: TcxCanvas;
                                     AViewInfo: TcxGridTableDataCellViewInfo;
                                     const AInfo: TInfoBasico): Boolean;
                                     overload;
function PintarCeldaConCuadradoColor(ACanvas: TcxCanvas;
                                     AViewInfo: TcxGridTableDataCellViewInfo;
                                     const AInfo: TInfoBasico;
                                     const ATexto: string): Boolean; overload;

// Pinta una celda cxGrid coloreando el texto con el color de la paleta.
// Usar dentro de OnCustomDrawCell:
//   if PintarCeldaConTextoColor(ACanvas, AViewInfo, AInfo) then
//     ADone := True;
function PintarCeldaConTextoColor(ACanvas: TcxCanvas;
                                  AViewInfo: TcxGridTableDataCellViewInfo;
                                  const AInfo: TInfoBasico): Boolean;

// Pinta solo el cuadradito de AInfo centrado en ARect, con lado ALado o
// el que quepa. El fondo lo pone quien llama. Lo usan la lista del combo
// (PintarOpcionComboConSwatch) y el boton-glifo del editor de Caja.
procedure PintarSwatchEnCanvas(ACanvas: TcxCanvas;
                               const ARect: TRect;
                               const AInfo: TInfoBasico;
                               ALado: Integer);

// Pinta una opcion de un TcxComboBox desde OnDrawItem: cuadradito de
// paleta delante del texto si AHayColor, o solo el texto con el mismo
// margen. Con DropDownListStyle = lsFixedList DevExpress usa el mismo
// evento para la caja de texto del editor (odComboBoxEdit en AState), y
// asi el color se ve tambien mientras se edita. Usa el fondo y la fuente
// que trae ACanvas (seleccion y foco ya aplicados) y deja el pincel como
// estaba.
procedure PintarOpcionComboConSwatch(ACanvas: TcxCanvas;
                                     const ARect: TRect;
                                     AState: TOwnerDrawState;
                                     const ATexto: string;
                                     AHayColor: Boolean;
                                     const AInfo: TInfoBasico);

// Lista desplegable de un TcxLookupComboBox: la columna ACampoHex pinta el
// cuadradito de paleta en vez del texto '#RRGGBB'. La lista no tiene evento
// de pintado propio, así que se le asigna un editor de solo lectura (su
// RepositoryItem), que pertenece a la propia lista.
procedure MostrarMuestraPaletaEnLista(AColumnas: TcxLookupDBGridColumns;
                                      const ACampoHex: string);

// Rellena ADict con NOMBRE_ATRIBUTO (uppercase) -> ID_ATRIBUTO para todos los
// atributos del articulo padre. Pensado para grids de stock que no conocen
// a priori el ID_VA de cada columna.
procedure CargarMapaAtributosArticulo(AConexion: TUniConnection;
                                      const ACodArt: string;
                                      ADict: TDictionary<string, string>);

// Variante global del anterior: NOMBRE_VA (uppercase) -> ID_ATB_VA para todos
// los atributos definidos en fza_variaciones_atributos. Pensada para grids que
// muestran lineas de articulos distintos (inventario, caja, ...) y necesitan
// un solo diccionario en vez de uno por articulo.
procedure CargarMapaAtributosGlobal(AConexion: TUniConnection;
  ADict: TDictionary<string, string>);

// Diccionario global cacheado en la propia libreria (carga perezosa). NO
// liberar el resultado — pertenece a la unidad. Pensado para que un form
// que quiera pintar cuadraditos solo tenga que llamar a
// `PintarCeldaSwatchSiAplica` desde su OnCustomDrawCell, sin gestionar
// estado ni inicializaciones.
function ObtenerMapaAtributosGlobal(
  AConexion: TUniConnection): TDictionary<string, string>;

// Invalida el diccionario global (llamar tras alta/baja en
// fza_variaciones_atributos o tras refrescar la paleta basica).
procedure InvalidarMapaAtributosGlobal;

// Helper "todo en uno" para usar desde OnCustomDrawCell. Busca un match en
// la paleta (usando ADict, o el diccionario global si ADict es nil) y, si
// procede, pinta la celda con cuadradito + texto. Devuelve True si pinto
// (el llamante debe poner ADone := True).
//
// Uso tipico (diccionario global):
//   procedure TfrmX.tvFooCustomDrawCell(Sender; ACanvas; AViewInfo; var ADone);
//   begin
//     if PintarCeldaSwatchSiAplica(ACanvas, AViewInfo, nil) then
//       ADone := True;
//   end;
function PintarCeldaSwatchSiAplica(AConexion: TUniConnection;
                                   ACanvas: TcxCanvas;
                                   AViewInfo: TcxGridTableDataCellViewInfo;
                                   ADict: TDictionary<string, string>): Boolean;

const
  // Atributo de color: el unico con paleta (HEX en sus basicos). Es el
  // ID_VA que usan las consultas de toda la aplicacion.
  ID_VA_COLOR = 'CO';

// ID_VA (CO, TAL...) del atributo cuyo nombre es ANombre segun el
// diccionario global, o '' si no existe.
function IdVaDeNombreAtributo(AConexion: TUniConnection;
                              const ANombre: string): string;

// True si ANombre es el atributo de color, el unico con paleta (HEX).
function EsAtributoConPaleta(AConexion: TUniConnection;
                             const ANombre: string): Boolean;

type
  // Color de paleta para el texto actual de un editor de atributo. Lo
  // aporta el host, que sabe el articulo y el atributo de la columna.
  TResolverColorEditor = function(AEditor: TcxComboBox;
    const ATexto: string; out AInfo: TInfoBasico): Boolean of object;

  // Cuadradito de color dentro de un TcxComboBox en linea que sigue
  // admitiendo teclear (lsEditFixedList). DevExpress solo pinta la caja
  // de texto con OnDrawItem en lsFixedList, asi que el hueco lo reserva
  // un boton transparente a la izquierda del texto y lo pinta esta clase
  // desde OnDrawButton del ViewInfo del editor. Al teclear no se toca
  // ninguna propiedad del editor (PropertiesChanged resincronizaria el
  // texto y perderia lo escrito): solo se guarda el color y se repinta.
  // Uso: ConfigurarBoton al crear la columna, MostrarBoton al asignarle
  // el atributo, PrepararEditor en OnInitEdit y ActualizarEditor al
  // cerrar la lista. OnChange y OnButtonClick del combo quedan
  // enganchados por ConfigurarBoton.
  TGlifoSwatchCombo = class
  private
    FAlPulsar: TcxEditButtonClickEvent;
    FIndiceBoton: Integer;
    FResolver: TResolverColorEditor;
    FSwatch: TInfoBasico;
    procedure Actualizar(AEditor: TcxComboBox; const ATexto: string);
    procedure CambiarTexto(Sender: TObject);
    procedure DibujarBoton(Sender: TcxEditButtonViewInfo;
      ACanvas: TcxCanvas; var AHandled: Boolean);
    procedure PulsarBoton(Sender: TObject; AButtonIndex: Integer);
  public
    // AAlPulsar: que hacer al pulsar el cuadradito; nil = abrir la lista.
    constructor Create(const AResolver: TResolverColorEditor;
      const AAlPulsar: TcxEditButtonClickEvent);
    class function IndiceBoton(
      APropiedades: TcxCustomEditProperties): Integer;
    procedure ConfigurarBoton(APropiedades: TcxComboBoxProperties);
    procedure MostrarBoton(APropiedades: TcxCustomEditProperties;
      AVisible: Boolean);
    procedure PrepararEditor(AEditor: TcxCustomEdit;
      const AValor: string);
    procedure ActualizarEditor(AEditor: TObject);
  end;

// Para celdas cuyo texto es "ARTICULO/COLOR[/TALLA...]" (rejillas de
// stock) o directamente un color: pinta el cuadradito del COLOR (primero
// la asignacion del articulo, luego la paleta global de color), nunca de
// otro atributo: una talla "100" no debe heredar el color basico "100".
function PintarCeldaSwatchColorDeSkuSiAplica(
  AConexion: TUniConnection;
  ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo): Boolean;

// Variante para una columna de atributo concreta: solo pinta si el texto
// es un valor del atributo AIdVa (primero la asignacion del articulo
// ACodArt, luego la paleta global de ESE atributo). Las otras variantes
// prueban el texto contra todos los atributos y una talla "100" heredaba
// el cuadradito del color basico "100".
function PintarCeldaSwatchAtributoSiAplica(
  AConexion: TUniConnection;
  ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo;
  const AIdVa, ACodArt: string): Boolean;

// Variante contextual para documentos de articulos. Resuelve primero la
// asignacion especifica del articulo (color proveedor -> color basico) y usa
// la paleta global solo como fallback. ATexto puede ser un valor o un SKU.
function PintarCeldaSwatchArticuloSiAplica(
  AConexion: TUniConnection;
  ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo;
  const ACodArt, ATexto: string;
  ADict: TDictionary<string, string>): Boolean;

// Busca un basico para `ATexto` probando cada ID_VA presente en `ADict`. Si
// el texto contiene '/', tambien prueba con el ultimo segmento tras la barra.
// Devuelve True en el primer match valido.
function BuscarInfoBasicoEnArticulo(AConexion: TUniConnection;
                                    const ATexto: string;
                                    ADict: TDictionary<string, string>;
                                    out AInfo: TInfoBasico): Boolean;

// Igual que BuscarInfoBasicoEnArticulo, dando prioridad a las asignaciones
// particulares del articulo antes de consultar el basico global del AV.
function BuscarInfoBasicoEnArticuloContextual(
  AConexion: TUniConnection;
  const ACodArt, ATexto: string;
  ADict: TDictionary<string, string>;
  out AInfo: TInfoBasico): Boolean;

// Recorre los valores de AColumn buscando textos que casen con la paleta
// basica del articulo (via `ADict`). Si encuentra al menos uno, ensancha la
// columna en ANCHO_SWATCH_PX para que el cuadradito de color no recorte el
// texto tras un ApplyBestFit (que solo mide caracteres). Devuelve True si
// se aplico el ensanche.
function AjustarAnchoColumnaParaSwatch(AConexion: TUniConnection;
                                       AColumn: TcxGridColumn;
                                       ADict: TDictionary<string, string>)
                                       : Boolean;

// Limpia AImages y la rellena con un swatch (cuadrado) por cada AV de
// `AAvs` (CODIGO_ATB esperado). El swatch se genera SOLO si existe en la
// paleta basica para (AIdVa, AV). El dict AAvToImageIndex queda con
// uppercase(AV) -> ImageIndex; los AV sin color en paleta no aparecen.
procedure RellenarImageListPaleta(AConexion: TUniConnection;
                                  AImages: TCustomImageList;
                                  const AIdVa: string;
                                  const AAvs: array of string;
                                  AAvToImageIndex: TDictionary<string,
                                  Integer>);

// Pinta un cuadradito de color en ABmp (lo redimensiona a ALado x ALado).
// Devuelve True si pinto algo (AInfo valido); False si no, y deja ABmp sin
// tocar. Util para glyphs de botones / iconos pequenyos.
function PintarSwatchEnBitmap(ABmp: TBitmap; const AInfo: TInfoBasico;
                              ALado: Integer = 14): Boolean;

// Muestra un combo DevExpress ya desplegado, con el cuadradito de paleta
// basica al lado de cada AV, colocado encima del editor que lo pide:
// pasa AScreenLeft/AScreenTop = pos en pantalla justo debajo del editor,
// y AWidthHint = ancho del editor (se expande si los AVs no caben). Enter
// o click eligen; Esc o click fuera cancelan. Si AScreenLeft/Top son
// negativos, sale centrado.
function SeleccionarAvConPaleta(AConexion: TUniConnection;
                                const AIdVa: string;
                                const AAvs: array of string;
                                const AValorActual: string;
                                out AValor: string;
                                AScreenLeft: Integer = -1;
                                AScreenTop: Integer = -1;
                                AWidthHint: Integer = 120;
                                const ACodArt: string = ''): Boolean;

implementation

uses
  cxContainer, cxGeometry, cxTextEdit, cxEditRepositoryItems;

type
  // Celda de la lista que pinta el HEX como cuadradito, sin texto.
  TMuestraPaletaViewInfo = class(TcxCustomTextEditViewInfo)
  private
    FInfo: TInfoBasico;
  protected
    procedure InternalPaint(ACanvas: TcxCanvas); override;
  end;

  TMuestraPaletaViewData = class(TcxCustomTextEditViewData)
  public
    procedure EditValueToDrawValue(const AEditValue: TcxEditValue;
      AViewInfo: TcxCustomEditViewInfo); override;
  end;

  TMuestraPaletaProperties = class(TcxTextEditProperties)
  public
    class function GetViewDataClass: TcxCustomEditViewDataClass; override;
    class function GetViewInfoClass: TcxContainerViewInfoClass; override;
  end;

  TMuestraPaletaRepositorio = class(TcxEditRepositoryTextItem)
  public
    class function GetEditPropertiesClass: TcxCustomEditPropertiesClass;
      override;
  end;

const
  // Lado a 96 ppp del cuadradito de la lista (se escala con la celda).
  LADO_MUESTRA_LISTA = 14;
  // TcxCanvas.DrawText espera banderas cx*, no DT_* de Windows: con
  // DT_SINGLELINE or DT_VCENTER el texto salia centrado en horizontal y,
  // si no cabia, recortado por los dos lados ("NEGRO" en la caja).
  BANDERAS_TEXTO_CELDA = cxSingleLine or cxAlignVCenter or cxAlignLeft or
    cxShowEndEllipsis;

var
  GCache        : TDictionary<string, TInfoBasico>;
  GCacheArticulo: TDictionary<string, TInfoBasico>;
  GCacheCargado : Boolean;
  // Mapa NOMBRE_VA -> ID_ATB_VA global (todas las variaciones del sistema),
  // cacheado para los grids que no tienen un articulo padre concreto
  // (inventario, caja, ...). Carga perezosa via ObtenerMapaAtributosGlobal.
  GMapaGlobal        : TDictionary<string, string>;
  GMapaGlobalCargado : Boolean;
  GLecturasPersistencia: ILecturasAtributosPaleta;
  GSelectorPresentacion: ISelectorAtributoPaleta;

procedure ConfigurarLecturasAtributosPaleta(
  const ALecturas: ILecturasAtributosPaleta);
begin
  GLecturasPersistencia := ALecturas;
  InvalidarCachePaleta;
  InvalidarMapaAtributosGlobal;
end;

procedure ConfigurarSelectorAtributoPaleta(
  const ASelector: ISelectorAtributoPaleta);
begin
  GSelectorPresentacion := ASelector;
end;

function ClaveCache(const AIdVA, ACodigoATB: string): string;
begin
  Result := UpperCase(Trim(AIdVA)) + '|' + UpperCase(Trim(ACodigoATB));
end;

function ClaveCacheArticulo(const ACodArt, AIdVA, AValor: string): string;
begin
  Result := UpperCase(Trim(ACodArt)) + '|' + UpperCase(Trim(AIdVA)) + '|' +
    UpperCase(Trim(AValor));
end;

function HexToColor(const AHex: string): TColor;
var
  s : string;
  r, g, b : Integer;
begin
  Result := clNone;
  s := Trim(AHex);
  if (Length(s) = 7) and (s[1] = '#') then
  begin
    if TryStrToInt('$' + Copy(s, 2, 2), r) and
       TryStrToInt('$' + Copy(s, 4, 2), g) and
       TryStrToInt('$' + Copy(s, 6, 2), b) then
      Result := RGB(r, g, b);
  end
  else if (Length(s) = 4) and (s[1] = '#') then
  begin
    if TryStrToInt('$' + s[2] + s[2], r) and
       TryStrToInt('$' + s[3] + s[3], g) and
       TryStrToInt('$' + s[4] + s[4], b) then
      Result := RGB(r, g, b);
  end;
end;

procedure CargarCache(AConexion: TUniConnection;
  const ALecturas: ILecturasAtributosPaleta);
var
  Entrada: TEntradaCacheBasico;
  Entradas: TArray<TEntradaCacheBasico>;
begin
  GCache.Clear;
  GCacheCargado := False;
  if (AConexion <> nil) and (ALecturas <> nil) then
  begin
    Entradas := ALecturas.ListarEntradasCache(AConexion);
    for Entrada in Entradas do
    begin
      if Entrada.Info.EsValido then
      begin
        GCache.AddOrSetValue(
          ClaveCache(Entrada.IdVariacion, Entrada.Codigo),
          Entrada.Info);
        if Trim(Entrada.Nombre) <> '' then
          GCache.AddOrSetValue(
            ClaveCache(Entrada.IdVariacion, Entrada.Nombre),
            Entrada.Info);
        if Trim(Entrada.Valor) <> '' then
          GCache.AddOrSetValue(
            ClaveCache(Entrada.IdVariacion, Entrada.Valor),
            Entrada.Info);
        if Trim(Entrada.Descripcion) <> '' then
          GCache.AddOrSetValue(
            ClaveCache(Entrada.IdVariacion, Entrada.Descripcion),
            Entrada.Info);
      end;
    end;
    GCacheCargado := True;
  end;
end;

procedure InvalidarCachePaleta;
begin
  if GCache <> nil then
    GCache.Clear;
  if GCacheArticulo <> nil then
    GCacheArticulo.Clear;
  GCacheCargado := False;
end;

function ObtenerBasicosArticulo(AConexion: TUniConnection;
  const ACodArt, AIdVA: string): TArray<string>;
begin
  Result := nil;
  if (GLecturasPersistencia <> nil) and (Trim(ACodArt) <> '') then
    Result := GLecturasPersistencia.ObtenerBasicosArticulo(
      AConexion,
      ACodArt,
      AIdVA);
end;

function ObtenerInfoBasico(AConexion: TUniConnection;
                           const AIdVA, ACodigoATB: string;
                           out AInfo: TInfoBasico): Boolean;
begin
  AInfo  := Default(TInfoBasico);
  Result := False;
  if (Trim(AIdVA) <> '') and (Trim(ACodigoATB) <> '') then
  begin
    if not GCacheCargado then
      CargarCache(AConexion, GLecturasPersistencia);
    if GCacheCargado and
       GCache.TryGetValue(ClaveCache(AIdVA, ACodigoATB), AInfo) then
      Result := AInfo.EsValido;
  end;
end;

function PintarCeldaConCuadradoColor(ACanvas: TcxCanvas;
                                     AViewInfo: TcxGridTableDataCellViewInfo;
                                     const AInfo: TInfoBasico): Boolean;
begin
  Result := PintarCeldaConCuadradoColor(ACanvas, AViewInfo, AInfo, '');
end;

function PintarCeldaConCuadradoColor(ACanvas: TcxCanvas;
                                     AViewInfo: TcxGridTableDataCellViewInfo;
                                     const AInfo: TInfoBasico;
                                     const ATexto: string): Boolean;
const
  LADO_CUADRADO = 16;
  MARGEN_IZQ    = 4;
  HUECO_TEXTO   = 4;
  // OJO: si tocas alguno de estos tres, revisa ANCHO_SWATCH_PX en la
  // interface (debe ser >= MARGEN_IZQ + LADO_CUADRADO + HUECO_TEXTO, mas la
  // holgura que se quiera dar al texto a la derecha del cuadradito).
var
  Bounds, Cuadrado, TxtRect : TRect;
  Texto : string;
  Alto, TopY : Integer;
begin
  Result := False;
  if (ACanvas <> nil) and (AViewInfo <> nil) and AInfo.EsValido then
  begin
  Bounds := AViewInfo.Bounds;
  if ATexto <> '' then
    Texto := ATexto
  else
    Texto := AViewInfo.Text;
  if (Texto = '') and (AViewInfo.GridRecord <> nil) then
    Texto := VarToStr(AViewInfo.GridRecord.Values[AViewInfo.Item.Index]);

  // Fondo de la celda con el color natural (selección/foco respetado por
  // Params)
  ACanvas.Brush.Color := AViewInfo.Params.Color;
  ACanvas.FillRect(Bounds);

  // Cuadrado de color centrado verticalmente
  Alto := Bounds.Bottom - Bounds.Top;
  if Alto > LADO_CUADRADO then
    TopY := Bounds.Top + (Alto - LADO_CUADRADO) div 2
  else
    TopY := Bounds.Top;
  Cuadrado := Rect(Bounds.Left + MARGEN_IZQ,
                   TopY,
                   Bounds.Left + MARGEN_IZQ + LADO_CUADRADO,
                   TopY + LADO_CUADRADO);
  // Relleno con el color de la paleta
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := AInfo.Color;
  ACanvas.FillRect(Cuadrado);
  // Borde fino negro. Usamos Rectangle con bsClear: FrameRect dibuja el
  // contorno con el brush (no con el pen), asi que para colores claros
  // como BLANCO el borde queda invisible.
  ACanvas.Brush.Style := bsClear;
  ACanvas.Pen.Color   := clBlack;
  ACanvas.Pen.Width   := 1;
  ACanvas.Rectangle(Cuadrado);
  ACanvas.Brush.Style := bsSolid;

  // Texto desplazado a la derecha del cuadrado
  TxtRect := Bounds;
  TxtRect.Left := Cuadrado.Right + HUECO_TEXTO;
  ACanvas.Font.Assign(AViewInfo.Params.Font);
  ACanvas.Font.Color := AViewInfo.Params.TextColor;
  ACanvas.Brush.Style := bsClear;
  ACanvas.DrawText(Texto, TxtRect, BANDERAS_TEXTO_CELDA);
  ACanvas.Brush.Style := bsSolid;

    Result := True;
  end;
end;

procedure PintarSwatchEnCanvas(ACanvas: TcxCanvas;
                               const ARect: TRect;
                               const AInfo: TInfoBasico;
                               ALado: Integer);
const
  LADO_MINIMO = 6;
var
  iLado: Integer;
  Cuadrado: TRect;
begin
  if (ACanvas <> nil) and AInfo.EsValido then
  begin
    iLado := ALado;
    if iLado > ARect.Width then
      iLado := ARect.Width;
    if iLado > ARect.Height then
      iLado := ARect.Height;
    if iLado < LADO_MINIMO then
      iLado := LADO_MINIMO;
    Cuadrado.Left := ARect.Left + (ARect.Width - iLado) div 2;
    Cuadrado.Top := ARect.Top + (ARect.Height - iLado) div 2;
    Cuadrado.Right := Cuadrado.Left + iLado;
    Cuadrado.Bottom := Cuadrado.Top + iLado;
    ACanvas.Brush.Style := bsSolid;
    ACanvas.Brush.Color := AInfo.Color;
    ACanvas.FillRect(Cuadrado);
    // Borde con el pen: FrameRect usa el brush y en colores claros como
    // BLANCO desapareceria.
    ACanvas.Brush.Style := bsClear;
    ACanvas.Pen.Color := clBlack;
    ACanvas.Pen.Width := 1;
    ACanvas.Rectangle(Cuadrado);
    ACanvas.Brush.Style := bsSolid;
  end;
end;

procedure TMuestraPaletaViewInfo.InternalPaint(ACanvas: TcxCanvas);
begin
  // Fondo de la fila (con la selección) sin texto; encima, el cuadradito.
  inherited InternalPaint(ACanvas);
  PintarSwatchEnCanvas(ACanvas, ClientRect, FInfo,
    ScaleFactor.Apply(LADO_MUESTRA_LISTA));
end;

procedure TMuestraPaletaViewData.EditValueToDrawValue(
  const AEditValue: TcxEditValue; AViewInfo: TcxCustomEditViewInfo);
var
  oVista: TMuestraPaletaViewInfo;
begin
  inherited EditValueToDrawValue(AEditValue, AViewInfo);
  oVista := AViewInfo as TMuestraPaletaViewInfo;
  oVista.FInfo := Default(TInfoBasico);
  oVista.FInfo.HexColor := Trim(oVista.Text);
  oVista.FInfo.Color := HexToColor(oVista.FInfo.HexColor);
  oVista.FInfo.EsValido := oVista.FInfo.Color <> clNone;
  oVista.Text := '';
end;

class function TMuestraPaletaProperties.GetViewDataClass:
  TcxCustomEditViewDataClass;
begin
  Result := TMuestraPaletaViewData;
end;

class function TMuestraPaletaProperties.GetViewInfoClass:
  TcxContainerViewInfoClass;
begin
  Result := TMuestraPaletaViewInfo;
end;

class function TMuestraPaletaRepositorio.GetEditPropertiesClass:
  TcxCustomEditPropertiesClass;
begin
  Result := TMuestraPaletaProperties;
end;

procedure MostrarMuestraPaletaEnLista(AColumnas: TcxLookupDBGridColumns;
                                      const ACampoHex: string);
var
  oColumna: TcxLookupDBGridColumn;
begin
  oColumna := AColumnas.ColumnByFieldName(ACampoHex);
  if oColumna <> nil then
    oColumna.RepositoryItem :=
      TMuestraPaletaRepositorio.Create(AColumnas.Grid);
end;

procedure PintarOpcionComboConSwatch(ACanvas: TcxCanvas;
                                     const ARect: TRect;
                                     AState: TOwnerDrawState;
                                     const ATexto: string;
                                     AHayColor: Boolean;
                                     const AInfo: TInfoBasico);
const
  // Caja de texto del editor: misma geometria que la celda del grid
  // (PintarCeldaConCuadradoColor) para que no salte al entrar a editar.
  LADO_EDITOR   = 16;
  MARGEN_EDITOR = 4;
  HUECO_EDITOR  = 4;
  // Opciones de la lista desplegable: cuadradito algo menor.
  LADO_LISTA    = 12;
  MARGEN_LISTA  = 6;
  HUECO_LISTA   = 8;
  LADO_MINIMO   = 6;
var
  iLado, iMargen, iHueco, iTop: Integer;
  ColorFondo: TColor;
  Cuadrado, TxtRect: TRect;
begin
  if ACanvas <> nil then
  begin
    if odComboBoxEdit in AState then
    begin
      iLado := LADO_EDITOR;
      iMargen := MARGEN_EDITOR;
      iHueco := HUECO_EDITOR;
    end
    else
    begin
      iLado := LADO_LISTA;
      iMargen := MARGEN_LISTA;
      iHueco := HUECO_LISTA;
    end;
    if iLado > ARect.Height - 2 then
      iLado := ARect.Height - 2;
    if iLado < LADO_MINIMO then
      iLado := LADO_MINIMO;
    ColorFondo := ACanvas.Brush.Color;
    ACanvas.Brush.Style := bsSolid;
    ACanvas.FillRect(ARect);
    TxtRect := ARect;
    TxtRect.Left := ARect.Left + iMargen;
    if AHayColor and AInfo.EsValido then
    begin
      iTop := ARect.Top;
      if ARect.Height > iLado then
        iTop := ARect.Top + (ARect.Height - iLado) div 2;
      Cuadrado := Rect(ARect.Left + iMargen,
                       iTop,
                       ARect.Left + iMargen + iLado,
                       iTop + iLado);
      PintarSwatchEnCanvas(ACanvas, Cuadrado, AInfo, iLado);
      TxtRect.Left := Cuadrado.Right + iHueco;
    end;
    ACanvas.Brush.Style := bsClear;
    ACanvas.DrawText(ATexto, TxtRect, BANDERAS_TEXTO_CELDA);
    ACanvas.Brush.Style := bsSolid;
    ACanvas.Brush.Color := ColorFondo;
  end;
end;

function PintarCeldaConTextoColor(ACanvas: TcxCanvas;
                                  AViewInfo: TcxGridTableDataCellViewInfo;
                                  const AInfo: TInfoBasico): Boolean;
var
  Bounds, TxtRect : TRect;
  Texto : string;
begin
  Result := False;
  if (ACanvas <> nil) and (AViewInfo <> nil) and AInfo.EsValido then
  begin
  Bounds := AViewInfo.Bounds;
  Texto  := AViewInfo.Text;

  ACanvas.Brush.Color := AViewInfo.Params.Color;
  ACanvas.FillRect(Bounds);

  TxtRect := Bounds;
  Inc(TxtRect.Left, 4);
  ACanvas.Font.Assign(AViewInfo.Params.Font);
  ACanvas.Font.Color := AInfo.Color;
  ACanvas.Font.Style := ACanvas.Font.Style + [fsBold];
  ACanvas.Brush.Style := bsClear;
  ACanvas.DrawText(Texto, TxtRect, BANDERAS_TEXTO_CELDA);
  ACanvas.Brush.Style := bsSolid;

    Result := True;
  end;
end;

procedure CargarMapaAtributosArticulo(AConexion: TUniConnection;
                                      const ACodArt: string;
                                      ADict: TDictionary<string, string>);
begin
  if GLecturasPersistencia <> nil then
    GLecturasPersistencia.CargarMapaArticulo(AConexion, ACodArt, ADict);
end;

procedure CargarMapaAtributosGlobal(AConexion: TUniConnection;
                                    ADict: TDictionary<string, string>);
begin
  if GLecturasPersistencia <> nil then
    GLecturasPersistencia.CargarMapaGlobal(AConexion, ADict);
end;

function ObtenerMapaAtributosGlobal(
  AConexion: TUniConnection): TDictionary<string, string>;
begin
  if GMapaGlobal = nil then
    GMapaGlobal := TDictionary<string, string>.Create;
  if not GMapaGlobalCargado then
  begin
    CargarMapaAtributosGlobal(AConexion, GMapaGlobal);
    GMapaGlobalCargado := True;
  end;
  Result := GMapaGlobal;
end;

procedure InvalidarMapaAtributosGlobal;
begin
  if GMapaGlobal <> nil then
    GMapaGlobal.Clear;
  GMapaGlobalCargado := False;
end;

function PintarCeldaSwatchSiAplica(AConexion: TUniConnection;
                                   ACanvas: TcxCanvas;
                                   AViewInfo: TcxGridTableDataCellViewInfo;
                                   ADict: TDictionary<string, string>): Boolean;
var
  Dict   : TDictionary<string, string>;
  Info   : TInfoBasico;
  sTexto : string;
begin
  Result := False;
  if (ACanvas <> nil) and (AViewInfo <> nil) then
  begin
    sTexto := AViewInfo.Text;
    if (sTexto = '') and
       (AViewInfo.GridRecord <> nil) and
       (AViewInfo.Item <> nil) then
      sTexto := VarToStr(AViewInfo.GridRecord.Values[AViewInfo.Item.Index]);
    if ADict <> nil then
      Dict := ADict
    else
      Dict := ObtenerMapaAtributosGlobal(AConexion);
    if (Dict <> nil) and (Dict.Count > 0) and
       BuscarInfoBasicoEnArticulo(AConexion, sTexto, Dict, Info) then
      Result := PintarCeldaConCuadradoColor(
        ACanvas, AViewInfo, Info, sTexto);
  end;
end;

function PintarCeldaSwatchArticuloSiAplica(
  AConexion: TUniConnection;
  ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo;
  const ACodArt, ATexto: string;
  ADict: TDictionary<string, string>): Boolean;
var
  Info: TInfoBasico;
  sTexto, sIdVa, sSegmento: string;
  Segmentos: TArray<string>;
  i: Integer;

  function Casa(const AValor: string): Boolean;
  begin
    Result := (AValor <> '') and
      (ObtenerInfoBasicoArticulo(
         AConexion, ACodArt, sIdVa, AValor, Info) or
       ObtenerInfoBasico(AConexion, sIdVa, AValor, Info));
  end;

begin
  Result := False;
  sTexto := Trim(ATexto);
  if (sTexto = '') and (AViewInfo <> nil) then
    sTexto := Trim(AViewInfo.Text);
  if (ACanvas <> nil) and (AViewInfo <> nil) and (sTexto <> '') then
  begin
    // Solo UN atributo: el de la columna (su caption es el nombre del
    // atributo: Color, Talla...) y, si la columna no es de atributo (el
    // texto es un SKU o un color suelto), el de color. Antes se probaba
    // el texto contra todos los atributos y la paleta global, y una
    // talla "100" heredaba el cuadradito del color basico "100".
    sIdVa := '';
    if AViewInfo.Item is TcxGridColumn then
      sIdVa := IdVaDeNombreAtributo(
        AConexion, TcxGridColumn(AViewInfo.Item).Caption);
    if sIdVa = '' then
      sIdVa := ID_VA_COLOR;
    Result := Casa(sTexto);
    if (not Result) and (Pos('/', sTexto) > 0) then
    begin
      Segmentos := sTexto.Split(['/']);
      for i := High(Segmentos) downto 0 do
      begin
        if not Result then
        begin
          sSegmento := Trim(Segmentos[i]);
          Result := Casa(sSegmento);
        end;
      end;
    end;
    if Result then
      Result := PintarCeldaConCuadradoColor(
        ACanvas, AViewInfo, Info, sTexto);
  end;
end;

function EsAtributoConPaleta(AConexion: TUniConnection;
                             const ANombre: string): Boolean;
begin
  Result := SameText(
    IdVaDeNombreAtributo(AConexion, ANombre), ID_VA_COLOR);
end;

{ TGlifoSwatchCombo }

const
  ETIQUETA_BOTON_SWATCH = 7301;
  ANCHO_BOTON_SWATCH = 22;
  LADO_SWATCH_EDITOR = 14;

constructor TGlifoSwatchCombo.Create(
  const AResolver: TResolverColorEditor;
  const AAlPulsar: TcxEditButtonClickEvent);
begin
  inherited Create;
  FResolver := AResolver;
  FAlPulsar := AAlPulsar;
  FIndiceBoton := -1;
end;

class function TGlifoSwatchCombo.IndiceBoton(
  APropiedades: TcxCustomEditProperties): Integer;
var
  I: Integer;
begin
  Result := -1;
  if APropiedades <> nil then
    for I := 0 to APropiedades.Buttons.Count - 1 do
      if (Result < 0) and
         (APropiedades.Buttons[I].Tag = ETIQUETA_BOTON_SWATCH) then
        Result := I;
end;

procedure TGlifoSwatchCombo.ConfigurarBoton(
  APropiedades: TcxComboBoxProperties);
var
  Boton: TcxEditButton;
begin
  // Transparente y sin resalte: solo reserva el hueco. Nace oculto y
  // MostrarBoton lo ensena en el atributo con paleta.
  if (APropiedades <> nil) and (IndiceBoton(APropiedades) < 0) then
  begin
    Boton := APropiedades.Buttons.Add;
    Boton.Kind := bkGlyph;
    Boton.Mode := TcxEditButtonMode.Glyph;
    Boton.Transparent := True;
    Boton.LeftAlignment := True;
    Boton.HotTrackMode := TcxEditButtonHotTrackMode.None;
    Boton.Width := ANCHO_BOTON_SWATCH;
    Boton.Tag := ETIQUETA_BOTON_SWATCH;
    Boton.Visible := False;
    APropiedades.OnButtonClick := PulsarBoton;
    APropiedades.OnChange := CambiarTexto;
  end;
end;

procedure TGlifoSwatchCombo.MostrarBoton(
  APropiedades: TcxCustomEditProperties; AVisible: Boolean);
var
  Indice: Integer;
begin
  // Sobre las propiedades de la columna, nunca sobre el editor activo.
  Indice := IndiceBoton(APropiedades);
  if (Indice >= 0) and
     (APropiedades.Buttons[Indice].Visible <> AVisible) then
    APropiedades.Buttons[Indice].Visible := AVisible;
end;

procedure TGlifoSwatchCombo.PrepararEditor(AEditor: TcxCustomEdit;
  const AValor: string);
var
  Combo: TcxComboBox;
begin
  // OnInitEdit: el editor ya tiene copiadas las propiedades de la columna.
  FIndiceBoton := -1;
  FSwatch := Default(TInfoBasico);
  if AEditor is TcxComboBox then
  begin
    Combo := TcxComboBox(AEditor);
    FIndiceBoton := IndiceBoton(Combo.Properties);
    Combo.ViewInfo.OnDrawButton := DibujarBoton;
    Actualizar(Combo, AValor);
  end;
end;

procedure TGlifoSwatchCombo.Actualizar(AEditor: TcxComboBox;
  const ATexto: string);
var
  Info: TInfoBasico;
begin
  // Con lsEditFixedList el texto ya llega autocompletado con la opcion
  // ("N" -> "NEGRO"). Solo se repinta el editor si cambia el color.
  Info := Default(TInfoBasico);
  if (FIndiceBoton >= 0) and Assigned(FResolver) then
    FResolver(AEditor, Trim(ATexto), Info);
  if (Info.EsValido <> FSwatch.EsValido) or
     (Info.Color <> FSwatch.Color) then
  begin
    FSwatch := Info;
    AEditor.Invalidate;
  end;
end;

procedure TGlifoSwatchCombo.ActualizarEditor(AEditor: TObject);
begin
  if AEditor is TcxComboBox then
    Actualizar(TcxComboBox(AEditor), TcxComboBox(AEditor).Text);
end;

procedure TGlifoSwatchCombo.CambiarTexto(Sender: TObject);
begin
  ActualizarEditor(Sender);
end;

procedure TGlifoSwatchCombo.DibujarBoton(Sender: TcxEditButtonViewInfo;
  ACanvas: TcxCanvas; var AHandled: Boolean);
begin
  // DevExpress llama con ACanvas = nil solo para saber si el boton se
  // pinta a medida. El fondo del editor ya esta: solo va el cuadradito.
  if (Sender <> nil) and (FIndiceBoton >= 0) and
     (Sender.ButtonIndex = FIndiceBoton) then
  begin
    AHandled := True;
    if (ACanvas <> nil) and FSwatch.EsValido then
      PintarSwatchEnCanvas(
        ACanvas, Sender.Bounds, FSwatch, LADO_SWATCH_EDITOR);
  end;
end;

procedure TGlifoSwatchCombo.PulsarBoton(Sender: TObject;
  AButtonIndex: Integer);
begin
  // Clic sobre el cuadradito: abre la lista igual que la flecha, salvo
  // que el host prefiera otra cosa.
  if (Sender is TcxComboBox) and (AButtonIndex >= 0) and
     (AButtonIndex = IndiceBoton(TcxComboBox(Sender).Properties)) then
  begin
    if Assigned(FAlPulsar) then
      FAlPulsar(Sender, AButtonIndex)
    else
      TcxComboBox(Sender).DroppedDown := True;
  end;
end;

function IdVaDeNombreAtributo(AConexion: TUniConnection;
                              const ANombre: string): string;
var
  Dict: TDictionary<string, string>;
begin
  Result := '';
  Dict := ObtenerMapaAtributosGlobal(AConexion);
  if (Dict <> nil) and (Trim(ANombre) <> '') then
    Dict.TryGetValue(UpperCase(Trim(ANombre)), Result);
end;

function PintarCeldaSwatchColorDeSkuSiAplica(
  AConexion: TUniConnection;
  ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo): Boolean;
var
  Info: TInfoBasico;
  sTexto, sCodArt, sColor: string;
  Segmentos: TArray<string>;
  bEncontrado: Boolean;
begin
  Result := False;
  if (ACanvas <> nil) and (AViewInfo <> nil) then
  begin
    sTexto := Trim(AViewInfo.Text);
    if (sTexto = '') and
       (AViewInfo.GridRecord <> nil) and
       (AViewInfo.Item <> nil) then
      sTexto := Trim(VarToStr(
        AViewInfo.GridRecord.Values[AViewInfo.Item.Index]));
    if sTexto <> '' then
    begin
      bEncontrado := False;
      if Pos('/', sTexto) > 0 then
      begin
        // El color es el primer atributo tras el articulo (orden 1).
        Segmentos := sTexto.Split(['/']);
        sCodArt := Trim(Segmentos[0]);
        sColor := Trim(Segmentos[1]);
        bEncontrado := (sColor <> '') and
          (ObtenerInfoBasicoArticulo(
             AConexion, sCodArt, ID_VA_COLOR, sColor, Info) or
           ObtenerInfoBasico(AConexion, ID_VA_COLOR, sColor, Info));
      end;
      if not bEncontrado then
        bEncontrado := ObtenerInfoBasico(
          AConexion, ID_VA_COLOR, sTexto, Info);
      if bEncontrado then
        Result := PintarCeldaConCuadradoColor(
          ACanvas, AViewInfo, Info, sTexto);
    end;
  end;
end;

function PintarCeldaSwatchAtributoSiAplica(
  AConexion: TUniConnection;
  ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo;
  const AIdVa, ACodArt: string): Boolean;
var
  Info: TInfoBasico;
  sTexto: string;
begin
  Result := False;
  if (ACanvas <> nil) and (AViewInfo <> nil) and (Trim(AIdVa) <> '') then
  begin
    sTexto := Trim(AViewInfo.Text);
    if (sTexto = '') and
       (AViewInfo.GridRecord <> nil) and
       (AViewInfo.Item <> nil) then
      sTexto := Trim(VarToStr(
        AViewInfo.GridRecord.Values[AViewInfo.Item.Index]));
    if (sTexto <> '') and
       (ObtenerInfoBasicoArticulo(
          AConexion, ACodArt, AIdVa, sTexto, Info) or
        ObtenerInfoBasico(AConexion, AIdVa, sTexto, Info)) then
      Result := PintarCeldaConCuadradoColor(
        ACanvas, AViewInfo, Info, sTexto);
  end;
end;

function BuscarInfoBasicoEnArticulo(AConexion: TUniConnection;
                                    const ATexto: string;
                                    ADict: TDictionary<string, string>;
                                    out AInfo: TInfoBasico): Boolean;
var
  Texto, IdVa, Segmento: string;
  Segmentos: TArray<string>;
  i: Integer;
begin
  AInfo  := Default(TInfoBasico);
  Result := False;
  if ADict <> nil then
  begin
    Texto := Trim(ATexto);
    if Texto <> '' then
    begin
      for IdVa in ADict.Values do
      begin
        if not Result then
          Result := ObtenerInfoBasico(AConexion, IdVa, Texto, AInfo);
      end;
      if not Result and (Pos('/', Texto) > 0) then
      begin
        Segmentos := Texto.Split(['/']);
        for i := High(Segmentos) downto 0 do
        begin
          if not Result then
          begin
            Segmento := Trim(Segmentos[i]);
            if Segmento <> '' then
            begin
              for IdVa in ADict.Values do
              begin
                if not Result then
                  Result := ObtenerInfoBasico(
                    AConexion, IdVa, Segmento, AInfo);
              end;
            end;
          end;
        end;
      end;
    end;
  end;
end;

function AjustarAnchoColumnaParaSwatch(AConexion: TUniConnection;
                                       AColumn: TcxGridColumn;
                                       ADict: TDictionary<string, string>)
                                       : Boolean;
var
  Tabla : TcxCustomGridTableView;
  i, n  : Integer;
  v     : Variant;
  Info  : TInfoBasico;
begin
  Result := False;
  if (AColumn <> nil) and (ADict <> nil) and (ADict.Count > 0) then
  begin
    Tabla := AColumn.GridView as TcxCustomGridTableView;
    if (Tabla <> nil) and (Tabla.DataController <> nil) then
    begin
      n := Tabla.DataController.RecordCount;
      if n > 0 then
      begin
        for i := 0 to n - 1 do
        begin
          if not Result then
          begin
            v := Tabla.DataController.Values[i, AColumn.Index];
            if not VarIsNull(v) and not VarIsClear(v) and
               BuscarInfoBasicoEnArticulo(
                 AConexion, VarToStr(v), ADict, Info) then
            begin
              AColumn.Width := AColumn.Width + ANCHO_SWATCH_PX;
              Result := True;
            end;
          end;
        end;
      end;
    end;
  end;
end;

procedure RellenarImageListPaleta(AConexion: TUniConnection;
                                  AImages: TCustomImageList;
                                  const AIdVa: string;
                                  const AAvs: array of string;
                                  AAvToImageIndex: TDictionary<string,
                                  Integer>);
const
  LADO = 14;
var
  i, Idx : Integer;
  Av, Clave : string;
  Info : TInfoBasico;
  Bmp : TBitmap;
begin
  if AImages <> nil then
  begin
    AImages.Clear;
    if AAvToImageIndex <> nil then
      AAvToImageIndex.Clear;
    if (Trim(AIdVa) <> '') and (Length(AAvs) > 0) then
    begin
      AImages.Width := LADO;
      AImages.Height := LADO;
      Bmp := TBitmap.Create;
      try
        Bmp.PixelFormat := pf24bit;
        Bmp.SetSize(LADO, LADO);
        for i := 0 to High(AAvs) do
        begin
          Av := AAvs[i];
          if ObtenerInfoBasico(AConexion, AIdVa, Av, Info) then
          begin
            Bmp.Canvas.Brush.Style := bsSolid;
            Bmp.Canvas.Brush.Color := Info.Color;
            Bmp.Canvas.FillRect(Rect(0, 0, LADO, LADO));
            Bmp.Canvas.Brush.Style := bsClear;
            Bmp.Canvas.Pen.Color := clBlack;
            Bmp.Canvas.Pen.Width := 1;
            Bmp.Canvas.Rectangle(0, 0, LADO, LADO);
            Idx := AImages.Add(Bmp, nil);
            if (Idx >= 0) and (AAvToImageIndex <> nil) then
            begin
              Clave := UpperCase(Trim(Av));
              AAvToImageIndex.AddOrSetValue(Clave, Idx);
            end;
          end;
        end;
      finally
        FreeAndNil(Bmp);
      end;
    end;
  end;
end;

function PintarSwatchEnBitmap(ABmp: TBitmap; const AInfo: TInfoBasico;
                              ALado: Integer): Boolean;
begin
  Result := False;
  if (ABmp <> nil) and AInfo.EsValido and (ALado >= 4) then
  begin
    ABmp.PixelFormat := pf24bit;
    ABmp.SetSize(ALado, ALado);
    ABmp.Canvas.Brush.Style := bsSolid;
    ABmp.Canvas.Brush.Color := AInfo.Color;
    ABmp.Canvas.FillRect(System.Types.Rect(0, 0, ALado, ALado));
    ABmp.Canvas.Brush.Style := bsClear;
    ABmp.Canvas.Pen.Color := clBlack;
    ABmp.Canvas.Pen.Width := 1;
    ABmp.Canvas.Rectangle(0, 0, ALado, ALado);
    Result := True;
  end;
end;

function BuscarInfoBasicoEnArticuloContextual(
  AConexion: TUniConnection;
  const ACodArt, ATexto: string;
  ADict: TDictionary<string, string>;
  out AInfo: TInfoBasico): Boolean;
var
  Texto, Segmento: string;
  Segmentos: TArray<string>;
  i: Integer;

  function ProbarValorArticulo(const AValor: string): Boolean;
  var
    IdVa: string;
  begin
    Result := False;
    if (Trim(ACodArt) <> '') and (Trim(AValor) <> '') then
      for IdVa in ADict.Values do
        if not Result then
          Result := ObtenerInfoBasicoArticulo(
            AConexion, ACodArt, IdVa, AValor, AInfo);
  end;

begin
  AInfo := Default(TInfoBasico);
  Result := False;
  Texto := Trim(ATexto);
  if (ADict <> nil) and (Texto <> '') then
  begin
    Result := ProbarValorArticulo(Texto);
    if (not Result) and (Pos('/', Texto) > 0) then
    begin
      Segmentos := Texto.Split(['/']);
      i := High(Segmentos);
      while (i >= 0) and (not Result) do
      begin
        Segmento := Trim(Segmentos[i]);
        Result := ProbarValorArticulo(Segmento);
        Dec(i);
      end;
    end;
    if not Result then
      Result := BuscarInfoBasicoEnArticulo(
        AConexion, Texto, ADict, AInfo);
  end;
end;

function ObtenerInfoBasicoArticulo(AConexion: TUniConnection;
  const ACodArt, AIdVA, AValor: string;
  out AInfo: TInfoBasico): Boolean;
var
  sClave: string;
begin
  AInfo := Default(TInfoBasico);
  Result := False;
  sClave := ClaveCacheArticulo(ACodArt, AIdVA, AValor);
  if (Trim(ACodArt) <> '') and (Trim(AValor) <> '') then
  begin
    if GCacheArticulo.TryGetValue(sClave, AInfo) then
      Result := AInfo.EsValido
    else if GLecturasPersistencia <> nil then
    begin
      Result := GLecturasPersistencia.ObtenerInfoBasicoArticulo(
        AConexion,
        ACodArt,
        AIdVA,
        AValor,
        AInfo);
      GCacheArticulo.AddOrSetValue(sClave, AInfo);
    end;
  end;
end;

function SeleccionarAvConPaleta(AConexion: TUniConnection;
                                const AIdVa: string;
                                const AAvs: array of string;
                                const AValorActual: string;
                                out AValor: string;
                                AScreenLeft, AScreenTop,
                                AWidthHint: Integer;
                                const ACodArt: string): Boolean;
begin
  AValor := '';
  Result := False;
  if (Length(AAvs) > 0) and
     (GSelectorPresentacion <> nil) then
    Result := GSelectorPresentacion.Seleccionar(
      AConexion,
      GLecturasPersistencia,
      AIdVa,
      AAvs,
      AValorActual,
      AValor,
      AScreenLeft,
      AScreenTop,
      AWidthHint,
      ACodArt);
end;

initialization
  GCache             := TDictionary<string, TInfoBasico>.Create;
  GCacheArticulo     := TDictionary<string, TInfoBasico>.Create;
  GCacheCargado      := False;
  GMapaGlobal        := nil;
  GMapaGlobalCargado := False;

finalization
  GSelectorPresentacion := nil;
  GLecturasPersistencia := nil;
  FreeAndNil(GCache);
  FreeAndNil(GCacheArticulo);
  FreeAndNil(GMapaGlobal);

end.
