{******************************************************************************}
{                                                                              }
{  Módulo:       inLibEditorCodigoSkin                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       17/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Adapta al skin DevExpress activo los controles VCL que el skin no pinta   }
{    en los editores de código: TSynEdit/TDBSynEdit (fondo, texto,             }
{    selección, línea activa, canal, guías y paleta del resaltador),           }
{    TTreeView y TScrollBar (tema claro u oscuro de Windows). Se reaplica      }
{    en caliente cuando cambia el skin de RootLookAndFeel.                     }
{******************************************************************************}
unit inLibEditorCodigoSkin;

{
  SynEdit no sabe nada de DevExpress: pinta con clWindow, clBtnFace y los
  colores fijos del resaltador del DFM. Sin tocar SynEdit, aquí se leen los
  colores del painter de RootLookAndFeel y se asignan a sus propiedades.

  La paleta del resaltador parte de una base clara u oscura según el fondo
  del editor y se corrige color a color hasta un contraste mínimo con ese
  fondo, para que también se lea con los skins de alto contraste.

  Las barras de desplazamiento son las nativas de Windows (las de SynEdit,
  TTreeView y TScrollBar); con un skin oscuro se les da el tema
  DarkMode_Explorer. Un enganche en WindowProc lo repone si se recrea la
  ventana del control.

  Uso: TfrmBase.DoShow llama a AplicarSkinEditoresCodigo(Self). Los
  cambios de skin posteriores se propagan solos a todas las ventanas.
}

interface

uses
  Vcl.Graphics, Vcl.Controls, Vcl.ComCtrls,
  SynEdit, SynEditHighlighter;

type
  TPaletaEditorCodigo = record
    Fondo: TColor;
    Texto: TColor;
    Seleccion: TColor;
    TextoSeleccion: TColor;
    LineaActiva: TColor;
    Canal: TColor;
    TextoCanal: TColor;
    Borde: TColor;
    Guias: TColor;
    PalabraClave: TColor;
    Cadena: TColor;
    Numero: TColor;
    Comentario: TColor;
    TipoDato: TColor;
    Funcion: TColor;
    Variable: TColor;
    Especial: TColor;
    EsOscuro: Boolean;
  end;

/// Paleta calculada a partir de los colores base de un skin. Pura: sin
/// acceso al skin, para poder probarla.
function CalcularPaletaEditorCodigo(AFondo, ATexto, ASeleccion,
  ATextoSeleccion: TColor): TPaletaEditorCodigo;

/// Paleta del skin activo (RootLookAndFeel.Painter).
function PaletaEditorCodigoSkin: TPaletaEditorCodigo;

function LuminanciaRelativa(AColor: TColor): Double;
function RelacionContraste(AColor1, AColor2: TColor): Double;
function MezclarColores(AColor1, AColor2: TColor; APeso2: Double): TColor;
/// Acerca AColor al blanco o al negro hasta alcanzar AMinimo de contraste
/// sobre AFondo.
function AsegurarContraste(AColor, AFondo: TColor;
  AMinimo: Double): TColor;

procedure AplicarPaletaResaltador(AResaltador: TSynCustomHighlighter;
  const APaleta: TPaletaEditorCodigo);
procedure AplicarSkinSynEdit(AEditor: TCustomSynEdit);
procedure AplicarSkinArbol(AArbol: TCustomTreeView);

/// Recorre AControl y sus hijos aplicando el skin a SynEdit, TTreeView y
/// TScrollBar.
procedure AplicarSkinEditoresCodigo(AControl: TWinControl);

implementation

uses
  Winapi.Windows, Winapi.Messages, Winapi.UxTheme, Winapi.CommCtrl,
  System.Classes, System.SysUtils, System.Math, Vcl.StdCtrls, Vcl.Forms,
  cxLookAndFeels, cxLookAndFeelPainters;

const
  CONTRASTE_TEXTO = 4.5;
  CONTRASTE_SECUNDARIO = 3.0;
  TEMA_OSCURO = 'DarkMode_Explorer';

type
  // Base de colores, en BGR (TColor), inspirada en los temas Light+ y
  // Dark+ de Visual Studio Code.
  TBaseResaltador = record
    PalabraClave: TColor;
    Cadena: TColor;
    Numero: TColor;
    Comentario: TColor;
    TipoDato: TColor;
    Funcion: TColor;
    Variable: TColor;
    Especial: TColor;
  end;

  TArbolAcceso = class(TCustomTreeView);

  TClaseAtributo = (caTexto, caPalabraClave, caCadena, caNumero,
    caComentario, caTipoDato, caFuncion, caVariable, caEspecial);

  // Repone el tema de las barras nativas si el control recrea su ventana.
  TTemaVentanaControl = class(TComponent)
  private
    FControl: TWinControl;
    FAnterior: TWndMethod;
    FOscuro: Boolean;
    procedure ProcesarMensaje(var AMensaje: TMessage);
  public
    constructor Create(AControl: TWinControl); reintroduce;
    destructor Destroy; override;
    procedure Aplicar(AOscuro: Boolean);
  end;

  // Escucha los cambios del skin raíz y los propaga a todas las ventanas.
  TOyenteSkinEditores = class(TComponent,
    IcxLookAndFeelNotificationListener)
  public
    function GetObject: TObject;
    procedure MasterLookAndFeelChanged(Sender: TcxLookAndFeel;
      AChangedValues: TcxLookAndFeelValues);
    procedure MasterLookAndFeelDestroying(Sender: TcxLookAndFeel);
  end;

const
  BASE_CLARA: TBaseResaltador = (
    PalabraClave: $00FF0000;
    Cadena: $001515A3;
    Numero: $00588609;
    Comentario: $00008000;
    TipoDato: $00997F26;
    Funcion: $00265E79;
    Variable: $00801000;
    Especial: $00DB00AF);
  BASE_OSCURA: TBaseResaltador = (
    PalabraClave: $00D69C56;
    Cadena: $007891CE;
    Numero: $00A8CEB5;
    Comentario: $0055996A;
    TipoDato: $00B0C94E;
    Funcion: $00AADCDC;
    Variable: $00FEDC9C;
    Especial: $00C086C5);

var
  // Único estado de la unidad: el oyente registrado en RootLookAndFeel
  // durante la vida del proceso.
  GOyente: TOyenteSkinEditores;

{ Colores }

function ComponenteLineal(AValor: Byte): Double;
var
  dCanal: Double;
begin
  dCanal := AValor / 255;
  if dCanal <= 0.03928 then
    Result := dCanal / 12.92
  else
    Result := Power((dCanal + 0.055) / 1.055, 2.4);
end;

function LuminanciaRelativa(AColor: TColor): Double;
var
  iRgb: Longint;
begin
  iRgb := ColorToRGB(AColor);
  Result := 0.2126 * ComponenteLineal(GetRValue(iRgb)) +
    0.7152 * ComponenteLineal(GetGValue(iRgb)) +
    0.0722 * ComponenteLineal(GetBValue(iRgb));
end;

function RelacionContraste(AColor1, AColor2: TColor): Double;
var
  dL1: Double;
  dL2: Double;
begin
  dL1 := LuminanciaRelativa(AColor1);
  dL2 := LuminanciaRelativa(AColor2);
  Result := (Max(dL1, dL2) + 0.05) / (Min(dL1, dL2) + 0.05);
end;

function MezclarColores(AColor1, AColor2: TColor; APeso2: Double): TColor;
var
  iRgb1: Longint;
  iRgb2: Longint;
  dPeso1: Double;
begin
  APeso2 := EnsureRange(APeso2, 0, 1);
  dPeso1 := 1 - APeso2;
  iRgb1 := ColorToRGB(AColor1);
  iRgb2 := ColorToRGB(AColor2);
  Result := RGB(
    Round(GetRValue(iRgb1) * dPeso1 + GetRValue(iRgb2) * APeso2),
    Round(GetGValue(iRgb1) * dPeso1 + GetGValue(iRgb2) * APeso2),
    Round(GetBValue(iRgb1) * dPeso1 + GetBValue(iRgb2) * APeso2));
end;

function AsegurarContraste(AColor, AFondo: TColor;
  AMinimo: Double): TColor;
var
  oExtremo: TColor;
  iPaso: Integer;
begin
  if LuminanciaRelativa(AFondo) < 0.5 then
    oExtremo := clWhite
  else
    oExtremo := clBlack;
  Result := ColorToRGB(AColor);
  iPaso := 0;
  while (iPaso < 20) and (RelacionContraste(Result, AFondo) < AMinimo) do
  begin
    Inc(iPaso);
    Result := MezclarColores(AColor, oExtremo, iPaso / 20);
  end;
end;

function ColorValido(AColor, ARespaldo: TColor): TColor;
begin
  if (AColor = clNone) or (AColor = clDefault) then
    Result := ColorToRGB(ARespaldo)
  else
    Result := ColorToRGB(AColor);
end;

function CalcularPaletaEditorCodigo(AFondo, ATexto, ASeleccion,
  ATextoSeleccion: TColor): TPaletaEditorCodigo;
var
  oBase: TBaseResaltador;
begin
  Result.Fondo := ColorValido(AFondo, clWindow);
  Result.EsOscuro := LuminanciaRelativa(Result.Fondo) < 0.5;
  Result.Texto := AsegurarContraste(ColorValido(ATexto, clWindowText),
    Result.Fondo, CONTRASTE_TEXTO);
  Result.Seleccion := ColorValido(ASeleccion, clHighlight);
  Result.TextoSeleccion := AsegurarContraste(
    ColorValido(ATextoSeleccion, clHighlightText), Result.Seleccion,
    CONTRASTE_TEXTO);
  Result.LineaActiva := MezclarColores(Result.Fondo, Result.Texto, 0.07);
  Result.Canal := MezclarColores(Result.Fondo, Result.Texto, 0.05);
  Result.TextoCanal := AsegurarContraste(
    MezclarColores(Result.Canal, Result.Texto, 0.55), Result.Canal,
    CONTRASTE_SECUNDARIO);
  Result.Borde := MezclarColores(Result.Fondo, Result.Texto, 0.2);
  Result.Guias := MezclarColores(Result.Fondo, Result.Texto, 0.25);
  if Result.EsOscuro then
    oBase := BASE_OSCURA
  else
    oBase := BASE_CLARA;
  Result.PalabraClave := AsegurarContraste(oBase.PalabraClave,
    Result.Fondo, CONTRASTE_TEXTO);
  Result.Cadena := AsegurarContraste(oBase.Cadena, Result.Fondo,
    CONTRASTE_TEXTO);
  Result.Numero := AsegurarContraste(oBase.Numero, Result.Fondo,
    CONTRASTE_TEXTO);
  Result.Comentario := AsegurarContraste(oBase.Comentario, Result.Fondo,
    CONTRASTE_TEXTO);
  Result.TipoDato := AsegurarContraste(oBase.TipoDato, Result.Fondo,
    CONTRASTE_TEXTO);
  Result.Funcion := AsegurarContraste(oBase.Funcion, Result.Fondo,
    CONTRASTE_TEXTO);
  Result.Variable := AsegurarContraste(oBase.Variable, Result.Fondo,
    CONTRASTE_TEXTO);
  Result.Especial := AsegurarContraste(oBase.Especial, Result.Fondo,
    CONTRASTE_TEXTO);
end;

function PaletaEditorCodigoSkin: TPaletaEditorCodigo;
var
  oPainter: TcxCustomLookAndFeelPainter;
begin
  oPainter := RootLookAndFeel.Painter;
  Result := CalcularPaletaEditorCodigo(
    oPainter.DefaultEditorBackgroundColor(False),
    oPainter.DefaultEditorTextColor(False),
    oPainter.DefaultSelectionColor,
    oPainter.DefaultSelectionTextColor);
end;

{ Resaltador }

function ContieneAlguno(const ANombre: string;
  const AClaves: array of string): Boolean;
var
  sClave: string;
begin
  Result := False;
  for sClave in AClaves do
    Result := Result or (Pos(sClave, ANombre) > 0);
end;

function ClasificarAtributo(const ANombre: string): TClaseAtributo;
var
  sNombre: string;
begin
  // Nombres internos de SynEditStrConst (SYNS_Attr*), en minúsculas.
  sNombre := LowerCase(ANombre);
  if ContieneAlguno(sNombre, ['conditionalcomment', 'consoleoutput',
    'exception', 'package', 'preprocessor', 'directive']) then
    Result := caEspecial
  else if Pos('comment', sNombre) > 0 then
    Result := caComentario
  else if ContieneAlguno(sNombre, ['reservedword', 'key', 'plsql',
    'sqlplus']) then
    Result := caPalabraClave
  else if ContieneAlguno(sNombre, ['string', 'char', 'value']) then
    Result := caCadena
  else if ContieneAlguno(sNombre, ['number', 'float', 'hex', 'octal']) then
    Result := caNumero
  else if ContieneAlguno(sNombre, ['datatype', 'type']) then
    Result := caTipoDato
  else if ContieneAlguno(sNombre, ['function', 'procname']) then
    Result := caFuncion
  else if ContieneAlguno(sNombre, ['variable', 'tablename', 'attribute',
    'delimitedidentifier']) then
    Result := caVariable
  else
    Result := caTexto;
end;

function ColorDeClase(AClase: TClaseAtributo;
  const APaleta: TPaletaEditorCodigo): TColor;
begin
  case AClase of
    caPalabraClave: Result := APaleta.PalabraClave;
    caCadena: Result := APaleta.Cadena;
    caNumero: Result := APaleta.Numero;
    caComentario: Result := APaleta.Comentario;
    caTipoDato: Result := APaleta.TipoDato;
    caFuncion: Result := APaleta.Funcion;
    caVariable: Result := APaleta.Variable;
    caEspecial: Result := APaleta.Especial;
  else
    // clNone: el editor usa su Font.Color.
    Result := clNone;
  end;
end;

procedure AplicarPaletaResaltador(AResaltador: TSynCustomHighlighter;
  const APaleta: TPaletaEditorCodigo);
var
  I: Integer;
  oAtributo: TSynHighlighterAttributes;
begin
  if AResaltador <> nil then
  begin
    AResaltador.BeginUpdate;
    try
      for I := 0 to AResaltador.AttrCount - 1 do
      begin
        oAtributo := AResaltador.Attribute[I];
        // Fondo transparente: así manda el del editor (el DFM fijaba
        // clWhite en varios atributos).
        oAtributo.Background := clNone;
        oAtributo.Foreground := ColorDeClase(
          ClasificarAtributo(oAtributo.Name), APaleta);
      end;
    finally
      AResaltador.EndUpdate;
    end;
  end;
end;

{ Tema de las barras nativas }

procedure PonerTemaVentana(AControl: TWinControl; AOscuro: Boolean);
begin
  if AControl.HandleAllocated then
  begin
    // Con nil se vuelve al tema por defecto del control.
    if AOscuro then
      SetWindowTheme(AControl.Handle, TEMA_OSCURO, nil)
    else
      SetWindowTheme(AControl.Handle, nil, nil);
  end;
end;

constructor TTemaVentanaControl.Create(AControl: TWinControl);
begin
  inherited Create(AControl);
  FControl := AControl;
  FAnterior := FControl.WindowProc;
  FControl.WindowProc := ProcesarMensaje;
end;

destructor TTemaVentanaControl.Destroy;
begin
  if not (csDestroying in FControl.ComponentState) then
    FControl.WindowProc := FAnterior;
  inherited Destroy;
end;

procedure TTemaVentanaControl.Aplicar(AOscuro: Boolean);
begin
  FOscuro := AOscuro;
  PonerTemaVentana(FControl, FOscuro);
  if FControl.HandleAllocated then
    SetWindowPos(FControl.Handle, 0, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or
      SWP_NOZORDER or SWP_NOACTIVATE or SWP_FRAMECHANGED);
end;

procedure TTemaVentanaControl.ProcesarMensaje(var AMensaje: TMessage);
begin
  FAnterior(AMensaje);
  if AMensaje.Msg = WM_CREATE then
    PonerTemaVentana(FControl, FOscuro);
end;

procedure AplicarTemaVentana(AControl: TWinControl; AOscuro: Boolean);
var
  I: Integer;
  oTema: TTemaVentanaControl;
begin
  oTema := nil;
  for I := 0 to AControl.ComponentCount - 1 do
    if AControl.Components[I] is TTemaVentanaControl then
      oTema := TTemaVentanaControl(AControl.Components[I]);
  if oTema = nil then
    oTema := TTemaVentanaControl.Create(AControl);
  oTema.Aplicar(AOscuro);
end;

{ Controles }

procedure AplicarPaletaSynEdit(AEditor: TCustomSynEdit;
  const APaleta: TPaletaEditorCodigo);
begin
  AEditor.Color := APaleta.Fondo;
  AEditor.Font.Color := APaleta.Texto;
  AEditor.SelectedColor.Background := APaleta.Seleccion;
  AEditor.SelectedColor.Foreground := APaleta.TextoSeleccion;
  AEditor.ActiveLineColor := APaleta.LineaActiva;
  AEditor.RightEdgeColor := APaleta.Borde;
  AEditor.IndentGuides.Color := APaleta.Guias;
  AEditor.Gutter.Gradient := False;
  AEditor.Gutter.Color := APaleta.Canal;
  AEditor.Gutter.BorderColor := APaleta.Borde;
  AEditor.Gutter.Font.Color := APaleta.TextoCanal;
  AEditor.CodeFolding.FolderBarLinesColor := APaleta.TextoCanal;
  AEditor.CodeFolding.CollapsedLineColor := APaleta.Guias;
  AplicarPaletaResaltador(AEditor.Highlighter, APaleta);
  AplicarTemaVentana(AEditor, APaleta.EsOscuro);
  AEditor.Invalidate;
end;

procedure AplicarPaletaArbol(AArbol: TCustomTreeView;
  const APaleta: TPaletaEditorCodigo);
begin
  TArbolAcceso(AArbol).Color := APaleta.Fondo;
  TArbolAcceso(AArbol).Font.Color := APaleta.Texto;
  AplicarTemaVentana(AArbol, APaleta.EsOscuro);
  if AArbol.HandleAllocated then
    TreeView_SetLineColor(AArbol.Handle, ColorToRGB(APaleta.Guias));
  AArbol.Invalidate;
end;

procedure AplicarSkinSynEdit(AEditor: TCustomSynEdit);
begin
  AplicarPaletaSynEdit(AEditor, PaletaEditorCodigoSkin);
end;

procedure AplicarSkinArbol(AArbol: TCustomTreeView);
begin
  AplicarPaletaArbol(AArbol, PaletaEditorCodigoSkin);
end;

procedure RecorrerControles(AControl: TWinControl;
  const APaleta: TPaletaEditorCodigo);
var
  I: Integer;
  oHijo: TControl;
begin
  for I := 0 to AControl.ControlCount - 1 do
  begin
    oHijo := AControl.Controls[I];
    if oHijo is TCustomSynEdit then
      AplicarPaletaSynEdit(TCustomSynEdit(oHijo), APaleta)
    else if oHijo is TCustomTreeView then
      AplicarPaletaArbol(TCustomTreeView(oHijo), APaleta)
    else if oHijo is TScrollBar then
      AplicarTemaVentana(TScrollBar(oHijo), APaleta.EsOscuro);
    if oHijo is TWinControl then
      RecorrerControles(TWinControl(oHijo), APaleta);
  end;
end;

procedure AplicarSkinEditoresCodigo(AControl: TWinControl);
begin
  if (AControl <> nil) and
     not (csDesigning in AControl.ComponentState) then
    RecorrerControles(AControl, PaletaEditorCodigoSkin);
end;

{ TOyenteSkinEditores }

function TOyenteSkinEditores.GetObject: TObject;
begin
  Result := Self;
end;

procedure TOyenteSkinEditores.MasterLookAndFeelChanged(
  Sender: TcxLookAndFeel; AChangedValues: TcxLookAndFeelValues);
var
  I: Integer;
  oPaleta: TPaletaEditorCodigo;
begin
  oPaleta := PaletaEditorCodigoSkin;
  for I := 0 to Screen.FormCount - 1 do
    RecorrerControles(Screen.Forms[I], oPaleta);
end;

procedure TOyenteSkinEditores.MasterLookAndFeelDestroying(
  Sender: TcxLookAndFeel);
begin
  // RootLookAndFeel solo se destruye al cerrar el proceso.
end;

initialization
  GOyente := TOyenteSkinEditores.Create(nil);
  RootLookAndFeel.AddChangeListener(GOyente);

finalization
  RootLookAndFeel.RemoveChangeListener(GOyente);
  FreeAndNil(GOyente);

end.
