{******************************************************************************}
{  TraduccionMovil: idioma del dispositivo y textos de la app móvil unificada. }
{  FZ-ISSUE-613/614/615/617. Copyright (c) Alejandro Laorden Hidalgo.          }
{                                                                              }
{  Regla: español, inglés, catalán o chino del dispositivo → ese idioma        }
{  (es-ES, en-GB, ca-ES, zh-CN); cualquier otro → inglés. Sin selector.        }
{  En Windows se puede forzar con el parámetro «-idioma=ca-ES» para revisar.   }
{                                                                              }
{  Cada módulo registra sus textos en su unidad Textos* (clave = español):     }
{    RegistrarTextos([T4('Guardar', 'Desar', 'Save', '保存'), ...]);            }
{  y en el código visible se escribe Tr('Guardar') o TrF('Hola %s', [sN]).      }
{  Un texto sin registrar se muestra en español y se anota en TextosSinTraducir }
{  para completarlo.                                                           }
{******************************************************************************}
unit TraduccionMovil;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, FMX.Types;

type
  TTextoTraducido = record
    Es: string;
    Ca: string;
    En: string;
    Zh: string;
  end;

function T4(const AEs, ACa, AEn, AZh: string): TTextoTraducido;
procedure RegistrarTextos(const ATextos: array of TTextoTraducido);
function Tr(const AEs: string): string;
function TrF(const AEs: string; const AArgs: array of const): string;
function IdiomaActual: string;
function FormatoIdioma: TFormatSettings;
procedure TraducirFormulario(ARaiz: TFmxObject);
function TextosSinTraducir: TArray<string>;

implementation

uses
  System.Generics.Defaults, FMX.Platform, FMX.Forms, FMX.Controls,
  FMX.Edit, FMX.ListBox, FMX.TabControl, FMX.StdCtrls, FMX.Objects;

var
  oTextos: TDictionary<string, TTextoTraducido>;
  oSinTraducir: TList<string>;
  sIdioma: string;
  oFormato: TFormatSettings;
  bFormatoListo: Boolean;

function T4(const AEs, ACa, AEn, AZh: string): TTextoTraducido;
begin
  Result.Es := AEs;
  Result.Ca := ACa;
  Result.En := AEn;
  Result.Zh := AZh;
end;

procedure RegistrarTextos(const ATextos: array of TTextoTraducido);
var
  oTexto: TTextoTraducido;
begin
  for oTexto in ATextos do
    oTextos.AddOrSetValue(oTexto.Es, oTexto);
end;

function IdiomaForzado: string;
var
  i: Integer;
  sParametro: string;
begin
  Result := '';
  for i := 1 to ParamCount do
  begin
    sParametro := ParamStr(i);
    if sParametro.StartsWith('-idioma=', True) or
       sParametro.StartsWith('/idioma=', True) then
      Result := Copy(sParametro, 9, MaxInt);
  end;
end;

function NormalizarIdioma(const ACodigo: string): string;
var
  sBase: string;
begin
  sBase := LowerCase(Copy(ACodigo, 1, 2));
  if sBase = 'es' then
    Result := 'es-ES'
  else if sBase = 'ca' then
    Result := 'ca-ES'
  else if sBase = 'zh' then
    Result := 'zh-CN'
  else
    Result := 'en-GB';
end;

function IdiomaActual: string;
var
  oServicio: IFMXLocaleService;
  sCodigo: string;
begin
  if sIdioma = '' then
  begin
    sCodigo := IdiomaForzado;
    if (sCodigo = '') and TPlatformServices.Current.SupportsPlatformService(
      IFMXLocaleService, oServicio) then
      sCodigo := oServicio.GetCurrentLangID;
    if sCodigo = '' then
      sCodigo := 'en';
    sIdioma := NormalizarIdioma(sCodigo);
  end;
  Result := sIdioma;
end;

function FormatoIdioma: TFormatSettings;
begin
  if not bFormatoListo then
  begin
    oFormato := TFormatSettings.Invariant;
    oFormato.CurrencyString := '€';
    oFormato.ShortTimeFormat := 'HH:mm';
    oFormato.LongTimeFormat := 'HH:mm:ss';
    if (IdiomaActual = 'es-ES') or (IdiomaActual = 'ca-ES') then
    begin
      oFormato.DecimalSeparator := ',';
      oFormato.ThousandSeparator := '.';
      oFormato.ShortDateFormat := 'dd/MM/yyyy';
      oFormato.CurrencyFormat := 3;
      oFormato.NegCurrFormat := 8;
    end
    else if IdiomaActual = 'zh-CN' then
    begin
      oFormato.DecimalSeparator := '.';
      oFormato.ThousandSeparator := ',';
      oFormato.ShortDateFormat := 'yyyy/MM/dd';
      oFormato.CurrencyFormat := 0;
      oFormato.NegCurrFormat := 1;
    end
    else
    begin
      oFormato.DecimalSeparator := '.';
      oFormato.ThousandSeparator := ',';
      oFormato.ShortDateFormat := 'dd/MM/yyyy';
      oFormato.CurrencyFormat := 0;
      oFormato.NegCurrFormat := 1;
    end;
    oFormato.DateSeparator := '/';
    oFormato.TimeSeparator := ':';
    bFormatoListo := True;
  end;
  Result := oFormato;
end;

function Tr(const AEs: string): string;
var
  oTexto: TTextoTraducido;
  sIdiomaActual: string;
begin
  Result := AEs;
  if AEs = '' then
    Result := ''
  else if oTextos.TryGetValue(AEs, oTexto) then
  begin
    sIdiomaActual := IdiomaActual;
    if sIdiomaActual = 'ca-ES' then
      Result := oTexto.Ca
    else if sIdiomaActual = 'en-GB' then
      Result := oTexto.En
    else if sIdiomaActual = 'zh-CN' then
      Result := oTexto.Zh;
    if Result = '' then
      Result := oTexto.En;
    if Result = '' then
      Result := AEs;
  end
  else if not oSinTraducir.Contains(AEs) then
    oSinTraducir.Add(AEs);
end;

function TrF(const AEs: string; const AArgs: array of const): string;
begin
  Result := Format(Tr(AEs), AArgs, FormatoIdioma);
end;

procedure TraducirFormulario(ARaiz: TFmxObject);
var
  i: Integer;
  oHijo: TFmxObject;
begin
  if ARaiz is TCommonCustomForm then
    TCommonCustomForm(ARaiz).Caption := Tr(TCommonCustomForm(ARaiz).Caption);
  // TTextControl: TListBoxItem, TTabItem, TExpander, TMenuItem...
  // TPresentedTextControl: TLabel, TButton, TSpeedButton, TCheckBox,
  // TRadioButton, TGroupBox (no derivan de TTextControl).
  // TText: rótulos de FMX.Objects. TCustomEdit.Text es dato: no se toca.
  if ARaiz is TTextControl then
    TTextControl(ARaiz).Text := Tr(TTextControl(ARaiz).Text)
  else if ARaiz is TPresentedTextControl then
    TPresentedTextControl(ARaiz).Text :=
      Tr(TPresentedTextControl(ARaiz).Text)
  else if ARaiz is TText then
    TText(ARaiz).Text := Tr(TText(ARaiz).Text);
  if ARaiz is TCustomEdit then
    TCustomEdit(ARaiz).TextPrompt := Tr(TCustomEdit(ARaiz).TextPrompt);
  if ARaiz is TControl then
    TControl(ARaiz).Hint := Tr(TControl(ARaiz).Hint);
  if ARaiz is TCustomComboBox then
    for i := 0 to TCustomComboBox(ARaiz).Items.Count - 1 do
      TCustomComboBox(ARaiz).Items[i] := Tr(TCustomComboBox(ARaiz).Items[i]);
  if not (ARaiz is TCustomComboBox) then
    for i := 0 to ARaiz.ChildrenCount - 1 do
    begin
      oHijo := ARaiz.Children[i];
      TraducirFormulario(oHijo);
    end;
end;

function TextosSinTraducir: TArray<string>;
begin
  Result := oSinTraducir.ToArray;
end;

initialization
  oTextos := TDictionary<string, TTextoTraducido>.Create;
  oSinTraducir := TList<string>.Create;

finalization
  oSinTraducir.Free;
  oTextos.Free;

end.
