{******************************************************************************}
{                                                                              }
{  Modulo:       inLibSeparadorDecimalTeclado                                  }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       05/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Punto y coma indistintos como separador decimal en los editores           }
{    numericos DevExpress (spin, moneda, calculadora): el caracter tecleado    }
{    que no es el separador regional se traduce a el antes de llegar al        }
{    editor, que lo descartaba como separador de miles (3.5 -> 35).            }
{    FZ-ISSUE-204.                                                             }
{******************************************************************************}
unit inLibSeparadorDecimalTeclado;

interface

uses
  Winapi.Windows, Vcl.Controls, cxEdit;

// True si AControl (o el editor que lo contiene, como el control interno
// de un editor en celda de cxGrid) es un editor numerico con decimales.
function EsEditorNumericoDecimal(AControl: TWinControl): Boolean;

// Si AMsg es la pulsacion de '.' o ',' distinta del separador decimal
// regional dirigida a un editor numerico, la cambia por el separador y
// devuelve True. El mensaje sigue su curso (no se marca como tratado).
function TraducirSeparadorDecimal(var AMsg: TMsg): Boolean;

// FZ-ISSUE-223 (texto pegado, lectores): un unico '.' o ',' se toma como
// separador decimal regional ('3.5' -> '3,5'). Con los dos, el ultimo es
// el decimal y el otro solo vale como miles en grupos de 3 ('1.234,5' ->
// '1234,5'). False si es ambiguo ('1.234.567', '12.34,5'); entonces
// ANormalizado es el texto sin tocar.
function NormalizarTextoDecimal(const ATexto: string;
  out ANormalizado: string): Boolean;

// FZ-ISSUE-223: pega ATexto en el editor numerico ya normalizado. La
// mascara del editor descartaba los separadores que no encajaban antes de
// validar ('3.5' -> 35, '1.234.567' -> 1234567). True si se ha tratado:
// pegado normalizado, o rechazado con el motivo en AAviso. False si no es
// un numero (lo pega el editor como siempre).
function PegarTextoDecimal(AEditor: TcxCustomEdit; const ATexto: string;
  out AAviso: string): Boolean;

// Decimales que admite la mascara de cantidad de FZ-205 del editor; -1 si
// el editor no la lleva.
function DecimalesMascaraCantidad(AEditor: TcxCustomEdit): Integer;

// FZ-ISSUE-223: aviso si una mascara de cantidad de ADecimales decimales
// (FZ-205) va a descartar en silencio ACaracter escrito sobre la seleccion
// de ATexto: segundo separador o decimal de mas. Vacia si cabe; tambien
// con ADecimales < 0 (sin mascara de cantidad).
function AvisoEntradaDecimal(ADecimales: Integer; const ATexto: string;
  ASelStart, ASelLength: Integer; ACaracter: Char): string;

// AvisoEntradaDecimal con el texto, la seleccion y la mascara del editor.
function AvisoCaracterDecimal(AEditor: TcxCustomEdit;
  ACaracter: Char): string;

// Gancho de Application.OnMessage: Ctrl+V / Mayus+Insert y caracteres
// tecleados en editores numericos. True si el mensaje queda tratado.
function ControlarEntradaDecimal(var AMsg: TMsg): Boolean;

// FZ-ISSUE-457: valida la insercion antes de que llegue al editor.
// Conserva teclas de control; admite signo solo al principio.
function CaracterNumericoPermitido(const ATexto: string;
  ASelStart, ASelLength: Integer; ACaracter: Char;
  ADecimales: Boolean): Boolean;

implementation

uses
  Winapi.Messages, Winapi.CommCtrl, System.SysUtils, System.RegularExpressions,
  Data.DB, Vcl.Clipbrd, cxTextEdit, cxMaskEdit, cxSpinEdit, cxCurrencyEdit,
  cxCalc, cxLookupEdit, cxGridCustomView, cxGridCustomTableView,
  cxGridDBTableView,
  inLibMsgArticulos;

// Celda de cxGrid con editor de texto (o mascara) ligada a un campo
// decimal: el editor descartaba el punto como separador de miles.
function ColumnaCeldaGrid(AControl: TWinControl): TcxCustomGridTableItem;
var
  Vista: TcxCustomGridView;
begin
  Result := nil;
  Vista := nil;
  while (AControl <> nil) and not (AControl is TcxGridSite) do
    AControl := AControl.Parent;
  if AControl is TcxGridSite then
    Vista := TcxGridSite(AControl).GridView;
  if Vista is TcxCustomGridTableView then
  begin
    Result := TcxCustomGridTableView(Vista).Controller.EditingItem;
    if Result = nil then
      Result := TcxCustomGridTableView(Vista).Controller.FocusedItem;
  end;
end;

function CampoCeldaGrid(AControl: TWinControl): TField;
var
  Columna: TcxCustomGridTableItem;
begin
  Result := nil;
  Columna := ColumnaCeldaGrid(AControl);
  if Columna is TcxGridDBColumn then
    Result := TcxGridDBColumn(Columna).DataBinding.Field;
end;

// Incluye las tallas de venta, que usan columnas sin campo de BBDD.
function EsCeldaNumerica(AControl: TWinControl;
  out ADecimales: Boolean): Boolean;
var
  Columna: TcxCustomGridTableItem;
  Campo: TField;
  Propiedades: TcxCustomEditProperties;
begin
  Campo := CampoCeldaGrid(AControl);
  Result := Campo is TNumericField;
  ADecimales := False;
  if Campo <> nil then
    ADecimales := Campo.DataType in
      [ftFloat, ftCurrency, ftBCD, ftFMTBcd, ftExtended, ftSingle];
  Columna := ColumnaCeldaGrid(AControl);
  if Columna <> nil then
  begin
    Propiedades := Columna.Properties;
    if Columna.RepositoryItem <> nil then
      Propiedades := Columna.RepositoryItem.Properties;
    if Propiedades <> nil then
    begin
      ADecimales := ADecimales or
        (Propiedades is TcxCurrencyEditProperties) or
        (Propiedades is TcxCalcEditProperties) or
        ((Propiedades.ClassType = TcxSpinEditProperties) and
         (TcxSpinEditProperties(Propiedades).ValueType = vtFloat));
      Result := Result or ADecimales or
        (Propiedades.ClassType = TcxSpinEditProperties);
      // El lookup escribe nombres aunque su clave sea un ID numerico.
      if Propiedades is TcxCustomLookupEditProperties then
      begin
        Result := False;
        ADecimales := False;
      end;
    end;
  end;
end;

function EsCeldaGridDecimal(AEditor: TcxCustomEdit): Boolean;
var
  Campo: TField;
begin
  Result := False;
  Campo := nil;
  // La columna sin propiedades usa el editor por defecto de DevExpress
  // para campos float, TcxMaskEditProperties (no TcxTextEditProperties):
  // vale cualquier editor de texto, el filtro real es el tipo del campo.
  if (AEditor.ActiveProperties is TcxCustomTextEditProperties) and
     not (AEditor.ActiveProperties is TcxCustomLookupEditProperties) then
    Campo := CampoCeldaGrid(AEditor);
  if Campo <> nil then
    Result := Campo.DataType in
      [ftFloat, ftCurrency, ftBCD, ftFMTBcd, ftExtended, ftSingle];
end;

function EsEditorNumericoDecimal(AControl: TWinControl): Boolean;
var
  Control: TWinControl;
  Propiedades: TcxCustomEditProperties;
begin
  Result := False;
  Control := AControl;
  while (Control <> nil) and not (Control is TcxCustomEdit) do
    Control := Control.Parent;
  if Control <> nil then
  begin
    Propiedades := TcxCustomEdit(Control).ActiveProperties;
    // TcxTimeEditProperties tambien es un spin: se excluye al pedir la
    // clase concreta TcxSpinEditProperties.
    Result := (Propiedades is TcxCurrencyEditProperties) or
      (Propiedades is TcxCalcEditProperties) or
      ((Propiedades is TcxSpinEditProperties) and
       (TcxSpinEditProperties(Propiedades).ValueType = vtFloat)) or
      EsCeldaGridDecimal(TcxCustomEdit(Control));
  end;
end;

// Miles validos: el separador de miles solo entre grupos de 3 cifras y
// antes del decimal ('1.234,5'; no '12.34,5').
function MilesValidos(const AEntero: string; AMiles: Char): Boolean;
var
  Grupos: TArray<string>;
  sPrimero: string;
  i: Integer;
begin
  Grupos := AEntero.Split([AMiles]);
  Result := Length(Grupos) > 1;
  if Result then
  begin
    sPrimero := Grupos[0];
    if (sPrimero <> '') and (sPrimero[1] = '-') then
      Delete(sPrimero, 1, 1);
    Result := (Length(sPrimero) >= 1) and (Length(sPrimero) <= 3);
    for i := 1 to High(Grupos) do
      if Length(Grupos[i]) <> 3 then
        Result := False;
  end;
end;

function NormalizarTextoDecimal(const ATexto: string;
  out ANormalizado: string): Boolean;
var
  sTexto, sEntero, sDecimal: string;
  cDecimal, cMiles: Char;
  iPos: Integer;
begin
  sTexto := Trim(ATexto);
  ANormalizado := sTexto;
  Result := True;
  if (Pos('.', sTexto) > 0) and (Pos(',', sTexto) > 0) then
  begin
    // Los dos: el ultimo es el decimal y el otro, miles en grupos de 3.
    if LastDelimiter('.', sTexto) > LastDelimiter(',', sTexto) then
      cDecimal := '.'
    else
      cDecimal := ',';
    if cDecimal = '.' then
      cMiles := ','
    else
      cMiles := '.';
    iPos := LastDelimiter(cDecimal, sTexto);
    sEntero := Copy(sTexto, 1, iPos - 1);
    sDecimal := Copy(sTexto, iPos + 1, MaxInt);
    Result := (Pos(cDecimal, sEntero) = 0) and
      (Pos(cMiles, sDecimal) = 0) and MilesValidos(sEntero, cMiles);
    if Result then
      ANormalizado := StringReplace(sEntero, cMiles, '', [rfReplaceAll]) +
        FormatSettings.DecimalSeparator + sDecimal;
  end
  else if (Pos('.', sTexto) > 0) or (Pos(',', sTexto) > 0) then
  begin
    // Uno solo: es el decimal. Repetido ('1.234.567') es ambiguo.
    if Pos('.', sTexto) > 0 then
      cDecimal := '.'
    else
      cDecimal := ',';
    Result := Pos(cDecimal, sTexto) = LastDelimiter(cDecimal, sTexto);
    if Result then
      ANormalizado := StringReplace(sTexto, cDecimal,
        FormatSettings.DecimalSeparator, []);
  end;
end;

function EsTextoNumerico(const ATexto: string): Boolean;
var
  Caracter: Char;
begin
  Result := ATexto <> '';
  for Caracter in ATexto do
    if not CharInSet(Caracter, ['0'..'9', '.', ',', '-', '+', ' ']) then
      Result := False;
end;

function PegarTextoDecimal(AEditor: TcxCustomEdit; const ATexto: string;
  out AAviso: string): Boolean;
var
  sTexto, sNormalizado: string;
begin
  AAviso := '';
  sTexto := Trim(ATexto);
  Result := (AEditor is TcxCustomTextEdit) and EsTextoNumerico(sTexto) and
    (Pos('.', sTexto) + Pos(',', sTexto) > 0);
  if Result then
  begin
    // SelText solo cambia el texto visible: sin DoEditing ni la marca de
    // modificado, la celda de la rejilla descartaba el pegado al salir y
    // reponia el valor anterior (revalidacion de FZ-ISSUE-223).
    if NormalizarTextoDecimal(sTexto, sNormalizado) then
    begin
      if AEditor.DoEditing then
      begin
        TcxCustomTextEdit(AEditor).SelText := sNormalizado;
        AEditor.EditModified := True;
        AEditor.ModifiedAfterEnter := True;
      end;
    end
    else
      AAviso := Format(SErrorCantidadSeparadorAmbiguo, [sTexto]);
  end;
end;

// Decimales de la mascara de cantidad de FZ-205 ('-?\d*' o
// '-?\d*(\,\d{0,N})?'); -1 si el editor no la lleva.
function DecimalesMascaraCantidad(AEditor: TcxCustomEdit): Integer;
var
  Propiedades: TcxCustomMaskEditProperties;
  Coincidencia: TMatch;
begin
  Result := -1;
  if AEditor.ActiveProperties is TcxCustomMaskEditProperties then
  begin
    Propiedades := TcxCustomMaskEditProperties(AEditor.ActiveProperties);
    if Propiedades.MaskKind = emkRegExpr then
    begin
      if Propiedades.EditMask = '-?\d*' then
        Result := 0
      else
      begin
        Coincidencia := TRegEx.Match(Propiedades.EditMask,
          '^-\?\\d\*\(\\.\\d\{0,(\d+)\}\)\?$');
        if Coincidencia.Success then
          Result := StrToInt(Coincidencia.Groups[1].Value);
      end;
    end;
  end;
end;

function AvisoEntradaDecimal(ADecimales: Integer; const ATexto: string;
  ASelStart, ASelLength: Integer; ACaracter: Char): string;
var
  iSeparador: Integer;
  sTexto: string;
  Separador: Char;
begin
  Result := '';
  if ADecimales >= 0 then
  begin
    Separador := FormatSettings.DecimalSeparator;
    // Texto que quedaria al escribir el caracter sobre la seleccion.
    sTexto := Copy(ATexto, 1, ASelStart) + ACaracter +
      Copy(ATexto, ASelStart + ASelLength + 1, MaxInt);
    iSeparador := Pos(Separador, sTexto);
    if ACaracter = Separador then
    begin
      if ADecimales = 0 then
        Result := SAvisoCantidadSinDecimales
      else if iSeparador <> LastDelimiter(Separador, sTexto) then
        Result := SAvisoCantidadSeparadorRepetido;
    end
    else if CharInSet(ACaracter, ['0'..'9']) and (iSeparador > 0) and
            (Length(sTexto) - iSeparador > ADecimales) then
      Result := Format(SAvisoCantidadDecimalesMaximos, [ADecimales]);
  end;
end;

function AvisoCaracterDecimal(AEditor: TcxCustomEdit;
  ACaracter: Char): string;
var
  Editor: TcxCustomTextEdit;
begin
  Result := '';
  if AEditor is TcxCustomTextEdit then
  begin
    Editor := TcxCustomTextEdit(AEditor);
    Result := AvisoEntradaDecimal(DecimalesMascaraCantidad(Editor),
      Editor.Text, Editor.SelStart, Editor.SelLength, ACaracter);
  end;
end;

// Globo de aviso sobre el editor, sin modal: la celda sigue en edicion.
procedure MostrarAvisoEditor(AVentana: HWND; const ATexto: string);
var
  Globo: TEditBalloonTip;
begin
  FillChar(Globo, SizeOf(Globo), 0);
  Globo.cbStruct := SizeOf(Globo);
  Globo.pszTitle := PChar(SAvisoTituloCantidad);
  Globo.pszText := PChar(ATexto);
  Globo.ttiIcon := TTI_WARNING;
  if SendMessage(AVentana, EM_SHOWBALLOONTIP, 0, LPARAM(@Globo)) = 0 then
    MessageBeep(MB_ICONWARNING);
end;

function EditorNumericoDe(AVentana: HWND): TcxCustomEdit;
var
  Control: TWinControl;
  EsNumerico, Decimales: Boolean;
begin
  Result := nil;
  Control := FindControl(AVentana);
  EsNumerico := EsEditorNumericoDecimal(Control);
  EsNumerico := EsCeldaNumerica(Control, Decimales) or EsNumerico;
  while (Control <> nil) and not (Control is TcxCustomEdit) do
    Control := Control.Parent;
  if Control is TcxCustomEdit then
    EsNumerico := EsNumerico or
      (TcxCustomEdit(Control).ActiveProperties.ClassType =
        TcxSpinEditProperties);
  if EsNumerico and (Control is TcxCustomEdit) and
     (TcxCustomEdit(Control).ActiveProperties is
       TcxCustomTextEditProperties) then
    Result := TcxCustomEdit(Control);
end;

function CaracterNumericoPermitido(const ATexto: string;
  ASelStart, ASelLength: Integer; ACaracter: Char;
  ADecimales: Boolean): Boolean;
var
  TextoRestante: string;
begin
  Result := Ord(ACaracter) < 32;
  if not Result then
  begin
    TextoRestante := Copy(ATexto, 1, ASelStart) +
      Copy(ATexto, ASelStart + ASelLength + 1, MaxInt);
    Result := CharInSet(ACaracter, ['0'..'9']);
    if CharInSet(ACaracter, ['-', '+']) then
      Result := (ASelStart = 0) and
        (Pos('-', TextoRestante) = 0) and
        (Pos('+', TextoRestante) = 0);
    if CharInSet(ACaracter, ['.', ',']) then
      Result := ADecimales and (Pos('.', TextoRestante) = 0) and
        (Pos(',', TextoRestante) = 0);
    // No insertar delante de un signo que ya existe.
    if Result and (TextoRestante <> '') and (ASelStart = 0) and
       CharInSet(TextoRestante[1], ['-', '+']) then
      Result := False;
  end;
end;

function EsPegar(const AMsg: TMsg): Boolean;
var
  bControl, bMayusculas, bAlt: Boolean;
begin
  Result := False;
  if AMsg.message = WM_KEYDOWN then
  begin
    bControl := GetKeyState(VK_CONTROL) < 0;
    bMayusculas := GetKeyState(VK_SHIFT) < 0;
    bAlt := GetKeyState(VK_MENU) < 0;
    Result := (not bAlt) and
      (((AMsg.wParam = WPARAM(Ord('V'))) and bControl) or
       ((AMsg.wParam = WPARAM(VK_INSERT)) and bMayusculas and
        not bControl));
  end;
end;

function ControlarEntradaDecimal(var AMsg: TMsg): Boolean;
var
  Editor: TcxCustomEdit;
  Texto: TcxCustomTextEdit;
  Decimales: Boolean;
  Caracter: Char;
  sAviso, Normalizado, Candidato, Patron: string;
begin
  Result := False;
  sAviso := '';
  Editor := nil;
  if (AMsg.message = WM_CHAR) or EsPegar(AMsg) then
    Editor := EditorNumericoDe(AMsg.hwnd);
  if (Editor <> nil) and (AMsg.message = WM_CHAR) then
  begin
    Texto := TcxCustomTextEdit(Editor);
    Caracter := Char(AMsg.wParam);
    Result := not CaracterNumericoPermitido(Texto.Text,
      Texto.SelStart, Texto.SelLength, Caracter,
      EsEditorNumericoDecimal(Editor));
    sAviso := AvisoCaracterDecimal(Editor, Caracter);
    // La mascara lo iba a descartar igualmente: se avisa y no se pasa.
    Result := Result or (sAviso <> '');
  end
  else if (Editor <> nil) and
          (Clipboard.HasFormat(CF_UNICODETEXT) or
           Clipboard.HasFormat(CF_TEXT)) then
  begin
    // Letras pegadas tampoco deben alcanzar TField.AsFloat.
    Result := not EsTextoNumerico(Trim(Clipboard.AsText));
    if not Result and
       NormalizarTextoDecimal(Clipboard.AsText, Normalizado) then
    begin
      Texto := TcxCustomTextEdit(Editor);
      Candidato := Copy(Texto.Text, 1, Texto.SelStart) + Normalizado +
        Copy(Texto.Text, Texto.SelStart + Texto.SelLength + 1, MaxInt);
      Patron := '^[+-]?\d+';
      if EsEditorNumericoDecimal(Editor) then
        Patron := '^[+-]?(\d+(' +
          TRegEx.Escape(FormatSettings.DecimalSeparator) +
          '\d*)?|' + TRegEx.Escape(FormatSettings.DecimalSeparator) +
          '\d+)';
      Result := not TRegEx.IsMatch(Candidato, Patron + '$');
    end;
    if not Result then
      Result := PegarTextoDecimal(Editor, Clipboard.AsText, sAviso);
  end;
  // La primera tecla puede llegar al sitio de la rejilla antes de que
  // DevExpress cree el editor. Tambien se filtra en ese punto.
  if (Editor = nil) and (AMsg.message = WM_CHAR) then
  begin
    if EsCeldaNumerica(FindControl(AMsg.hwnd), Decimales) then
      Result := not CaracterNumericoPermitido('', 0, 0,
        Char(AMsg.wParam), Decimales);
  end;
  if sAviso <> '' then
    MostrarAvisoEditor(AMsg.hwnd, sAviso);
end;

function TraducirSeparadorDecimal(var AMsg: TMsg): Boolean;
var
  Caracter, Separador: Char;
  EsDecimal, DecimalesCelda: Boolean;
begin
  Result := False;
  if AMsg.message = WM_CHAR then
  begin
    Caracter := Char(AMsg.wParam);
    Separador := FormatSettings.DecimalSeparator;
    EsDecimal := EsEditorNumericoDecimal(FindControl(AMsg.hwnd));
    if EsCeldaNumerica(FindControl(AMsg.hwnd), DecimalesCelda) then
      EsDecimal := EsDecimal or DecimalesCelda;
    if ((Caracter = '.') or (Caracter = ',')) and
       (Caracter <> Separador) and
       EsDecimal then
    begin
      AMsg.wParam := WPARAM(Ord(Separador));
      Result := True;
    end;
  end;
end;

end.
