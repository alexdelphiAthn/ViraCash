{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFamiliasArbolVcl                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       18/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{  Descripción:                                                                }
{    Árbol jerárquico de familias sobre un TcxTreeList con casilla             }
{    "Incluir" y marca en cascada, el mismo de los filtros de informes.        }
{    La selección se lleva como lista CSV de códigos.                          }
{******************************************************************************}
unit inLibFamiliasArbolVcl;

interface

uses
  System.Classes, Vcl.Controls,
  cxTL, cxTLData, cxInplaceContainer, cxCheckBox,
  inLibFamiliasArbol;

type
  // Gobierna un TcxTreeList como árbol de familias con casilla "Incluir":
  // pinta la jerarquía padre→subfamilias, un clic o la barra espaciadora
  // alterna la familia enfocada y la marca se propaga en cascada a sus
  // subfamilias, de modo que el usuario elige el padre o el hijo según
  // convenga. La selección se lee y se fija como CSV de códigos.
  // Convención compartida con los filtros de los informes: sin marcar
  // nada = todas.
  TArbolFamiliasVcl = class
  private
    FArbol: TcxTreeList;
    FColNombre: TcxTreeListColumn;
    FColMarcado: TcxTreeListColumn;
    FColCodigo: TcxTreeListColumn;
    function NuevoNodo(APadre: TcxTreeListNode;
      const ACodigo, ANombre: string): TcxTreeListNode;
    function CrearColumna(const ACaption: string;
      AAncho: Integer): TcxTreeListColumn;
    procedure MarcarRama(ANodo: TcxTreeListNode; AValor: Boolean);
    procedure ArbolMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ArbolKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  public
    constructor Create(AArbol: TcxTreeList;
      const ACaptionNombre, ACaptionMarcado, ACaptionCodigo: string);
    // Reconstruye el árbol con la jerarquía de AFamilias. Una familia
    // cuelga de la raíz si no tiene padre o si su padre no está en la
    // lista; el guarda por código ya colocado corta jerarquías cíclicas.
    procedure Cargar(const AFamilias: TFamiliasArbol);
    // Alterna la marca del nodo y la propaga a sus subfamilias.
    procedure Alternar(ANodo: TcxTreeListNode);
    // Oculta las familias que no coinciden con ATexto (nombre o código);
    // un nodo sigue visible si algún descendiente coincide. No toca las
    // marcas, así una búsqueda no descarta selecciones ocultas.
    procedure Filtrar(const ATexto: string);
    procedure Desmarcar;
    // Marca las familias de la lista CSV (tal cual: el CSV ya trae las
    // subfamilias que se marcaron en cascada).
    procedure MarcarCsv(const ACsv: string);
    // CSV de las familias marcadas. Recorre todos los nodos, no solo los
    // visibles, para no perder selecciones ocultas por el buscador.
    function CsvMarcadas: string;
    function ContarMarcadas: Integer;
    property Arbol: TcxTreeList read FArbol;
  end;

implementation

uses
  Winapi.Windows, System.SysUtils, System.Types,
  System.Generics.Collections;

// Índices de columna del árbol (orden de creación).
const
  cFamNombre = 0;
  cFamMarcado = 1;
  cFamCodigo = 2;
  ANCHO_NOMBRE = 320;
  ANCHO_MARCADO = 70;
  ANCHO_CODIGO = 120;

constructor TArbolFamiliasVcl.Create(AArbol: TcxTreeList;
  const ACaptionNombre, ACaptionMarcado, ACaptionCodigo: string);
begin
  inherited Create;
  FArbol := AArbol;
  FArbol.OptionsBehavior.Sorting := False;
  FArbol.OptionsData.Editing := False;
  FArbol.OptionsData.Deleting := False;
  FArbol.OptionsData.Inserting := False;
  FArbol.OptionsSelection.MultiSelect := False;
  FArbol.OptionsView.Buttons := True;
  FArbol.OptionsView.Headers := True;
  FArbol.OptionsView.ShowRoot := True;
  if FArbol.Bands.Count = 0 then
    FArbol.Bands.Add;
  FColNombre := CrearColumna(ACaptionNombre, ANCHO_NOMBRE);
  FColMarcado := CrearColumna(ACaptionMarcado, ANCHO_MARCADO);
  FColMarcado.DataBinding.ValueType := 'Boolean';
  FColMarcado.PropertiesClass := TcxCheckBoxProperties;
  FColCodigo := CrearColumna(ACaptionCodigo, ANCHO_CODIGO);
  FArbol.OnMouseDown := ArbolMouseDown;
  FArbol.OnKeyDown := ArbolKeyDown;
end;

function TArbolFamiliasVcl.CrearColumna(const ACaption: string;
  AAncho: Integer): TcxTreeListColumn;
begin
  Result := FArbol.CreateColumn;
  Result.Position.BandIndex := 0;
  Result.Caption.Text := ACaption;
  Result.Width := AAncho;
  Result.Options.Editing := False;
end;

function TArbolFamiliasVcl.NuevoNodo(APadre: TcxTreeListNode;
  const ACodigo, ANombre: string): TcxTreeListNode;
begin
  if APadre = nil then
    Result := FArbol.Root.AddChild
  else
    Result := APadre.AddChild;
  Result.Texts[cFamNombre] := ANombre;
  Result.Texts[cFamCodigo] := ACodigo;
  Result.Values[cFamMarcado] := False;
end;

procedure TArbolFamiliasVcl.Cargar(const AFamilias: TFamiliasArbol);
var
  i: Integer;
  sClave: string;
  slCod: TStringList;
  slNom: TStringList;
  slPad: TStringList;
  conocidos: TStringList;
  colocados: TStringList;
  hijosDe: TObjectDictionary<string, TList<Integer>>;
  lst: TList<Integer>;

  procedure AnadirHijos(APadre: TcxTreeListNode; const AClave: string);
  var
    j: Integer;
    sub: TList<Integer>;
    nodo: TcxTreeListNode;
    idx: Integer;
  begin
    if hijosDe.TryGetValue(AClave, sub) then
      for j := 0 to sub.Count - 1 do
      begin
        idx := sub[j];
        if colocados.IndexOf(slCod[idx]) < 0 then
        begin
          colocados.Add(slCod[idx]);
          nodo := NuevoNodo(APadre, slCod[idx], slNom[idx]);
          AnadirHijos(nodo, slCod[idx]);
        end;
      end;
  end;

begin
  slCod := TStringList.Create;
  slNom := TStringList.Create;
  slPad := TStringList.Create;
  conocidos := TStringList.Create;
  colocados := TStringList.Create;
  hijosDe :=
    TObjectDictionary<string, TList<Integer>>.Create([doOwnsValues]);
  try
    conocidos.Sorted := True;
    colocados.Sorted := True;
    for i := 0 to Length(AFamilias) - 1 do
    begin
      slCod.Add(AFamilias[i].Codigo);
      slNom.Add(AFamilias[i].Nombre);
      slPad.Add(AFamilias[i].CodigoPadre);
      conocidos.Add(AFamilias[i].Codigo);
    end;
    // Mapa clave(padre)→índices de hijos. Clave vacía = familias raíz.
    for i := 0 to slCod.Count - 1 do
    begin
      sClave := slPad[i];
      if (sClave = '') or (conocidos.IndexOf(sClave) < 0) then
        sClave := '';
      if not hijosDe.TryGetValue(sClave, lst) then
      begin
        lst := TList<Integer>.Create;
        hijosDe.Add(sClave, lst);
      end;
      lst.Add(i);
    end;
    FArbol.BeginUpdate;
    try
      FArbol.Clear;
      AnadirHijos(nil, '');
    finally
      FArbol.EndUpdate;
    end;
  finally
    FreeAndNil(slCod);
    FreeAndNil(slNom);
    FreeAndNil(slPad);
    FreeAndNil(conocidos);
    FreeAndNil(colocados);
    FreeAndNil(hijosDe);
  end;
end;

procedure TArbolFamiliasVcl.MarcarRama(ANodo: TcxTreeListNode;
  AValor: Boolean);
var
  i: Integer;
begin
  if ANodo <> nil then
  begin
    ANodo.Values[cFamMarcado] := AValor;
    for i := 0 to ANodo.Count - 1 do
      MarcarRama(ANodo.Items[i], AValor);
  end;
end;

procedure TArbolFamiliasVcl.Alternar(ANodo: TcxTreeListNode);
var
  bNuevo: Boolean;
begin
  if ANodo <> nil then
  begin
    bNuevo := not (ANodo.Values[cFamMarcado] = True);
    FArbol.BeginUpdate;
    try
      MarcarRama(ANodo, bNuevo);
    finally
      FArbol.EndUpdate;
    end;
  end;
end;

procedure TArbolFamiliasVcl.Filtrar(const ATexto: string);
var
  sBusca: string;
  i: Integer;

  function Coincide(ANodo: TcxTreeListNode): Boolean;
  var
    j: Integer;
    bHijo: Boolean;
    bVisible: Boolean;
    sNombre: string;
    sCodigo: string;
  begin
    bHijo := False;
    for j := 0 to ANodo.Count - 1 do
      if Coincide(ANodo.Items[j]) then
        bHijo := True;
    sNombre := LowerCase(ANodo.Texts[cFamNombre]);
    sCodigo := LowerCase(ANodo.Texts[cFamCodigo]);
    bVisible := bHijo or (sBusca = '') or (Pos(sBusca, sNombre) > 0) or
      (Pos(sBusca, sCodigo) > 0);
    ANodo.Visible := bVisible;
    Result := bVisible;
  end;

begin
  sBusca := LowerCase(Trim(ATexto));
  FArbol.BeginUpdate;
  try
    for i := 0 to FArbol.Root.Count - 1 do
      Coincide(FArbol.Root.Items[i]);
  finally
    FArbol.EndUpdate;
  end;
  if sBusca <> '' then
    FArbol.FullExpand;
end;

procedure TArbolFamiliasVcl.Desmarcar;
var
  i: Integer;
begin
  FArbol.BeginUpdate;
  try
    for i := 0 to FArbol.Root.Count - 1 do
      MarcarRama(FArbol.Root.Items[i], False);
  finally
    FArbol.EndUpdate;
  end;
end;

procedure TArbolFamiliasVcl.MarcarCsv(const ACsv: string);
var
  i: Integer;
  slCodigos: TStringList;
  sCodigo: string;

  procedure Recorrer(ANodo: TcxTreeListNode);
  var
    j: Integer;
  begin
    ANodo.Values[cFamMarcado] :=
      slCodigos.IndexOf(ANodo.Texts[cFamCodigo]) >= 0;
    for j := 0 to ANodo.Count - 1 do
      Recorrer(ANodo.Items[j]);
  end;

begin
  slCodigos := TStringList.Create;
  try
    slCodigos.Sorted := True;
    for sCodigo in CodigosFamiliaDesdeCsv(ACsv) do
      slCodigos.Add(sCodigo);
    FArbol.BeginUpdate;
    try
      for i := 0 to FArbol.Root.Count - 1 do
        Recorrer(FArbol.Root.Items[i]);
    finally
      FArbol.EndUpdate;
    end;
  finally
    FreeAndNil(slCodigos);
  end;
end;

function TArbolFamiliasVcl.CsvMarcadas: string;
var
  i: Integer;
  sCsv: string;

  procedure Recorrer(ANodo: TcxTreeListNode);
  var
    j: Integer;
  begin
    if ANodo.Values[cFamMarcado] = True then
    begin
      if sCsv <> '' then
        sCsv := sCsv + ',';
      sCsv := sCsv + ANodo.Texts[cFamCodigo];
    end;
    for j := 0 to ANodo.Count - 1 do
      Recorrer(ANodo.Items[j]);
  end;

begin
  sCsv := '';
  for i := 0 to FArbol.Root.Count - 1 do
    Recorrer(FArbol.Root.Items[i]);
  Result := sCsv;
end;

function TArbolFamiliasVcl.ContarMarcadas: Integer;
begin
  Result := ContarCodigosFamilia(CsvMarcadas);
end;

procedure TArbolFamiliasVcl.ArbolMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FArbol.HitTest.Recalculate(Point(X, Y));
  if (Button = mbLeft) and (not (ssDouble in Shift)) and
     FArbol.HitTest.HitAtNode and
     (not FArbol.HitTest.HitAtButton) then
    Alternar(FArbol.HitTest.HitNode);
end;

procedure TArbolFamiliasVcl.ArbolKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_SPACE then
  begin
    Alternar(FArbol.FocusedNode);
    Key := 0;
  end;
end;

end.
