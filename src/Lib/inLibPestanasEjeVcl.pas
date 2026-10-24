{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPestanasEjeVcl                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       23/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Barra de pestañas del eje S (la copa) sobre una rejilla: «Todas» y una    }
{    por valor con su total, de inLibPestanasEje. Se esconde cuando el tipo    }
{    de variación no tiene pestañas. Conserva el valor elegido al recargar     }
{    y avisa al cambiar de pestaña (tercera dimensión, fase 3).                }
{******************************************************************************}
unit inLibPestanasEjeVcl;

interface

uses
  System.Classes, System.SysUtils,
  Vcl.Controls,
  cxPC, cxGridDBTableView, cxFilter, Data.DB,
  inLibPestanasEje;

type
  TAlCambiarPestanaEje = reference to procedure(const ACodigo: string);

  TControlPestanasEje = class
  private
    FPestanas: TcxTabControl;
    FModelo: TModeloPestanasEje;
    FCodigo: string;
    FCargando: Boolean;
    FAlCambiar: TAlCambiarPestanaEje;
    procedure PestanasChange(Sender: TObject);
  public
    // El control queda dentro de AParent con Align = alTop.
    constructor Create(AOwner: TComponent; AParent: TWinControl;
      const AAlCambiar: TAlCambiarPestanaEje);
    destructor Destroy; override;
    // Rehace las pestañas; si el valor elegido ya no existe vuelve a
    // «Todas». No avisa del cambio: quien recarga ya sabe el resultado.
    procedure Mostrar(const AModelo: TModeloPestanasEje);
    procedure Ocultar;
    // Vuelve a «Todas» sin avisar (antes de añadir líneas que aún no
    // tienen valor).
    procedure SeleccionarTodas;
    function HayPestanas: Boolean;
    // '' = «Todas».
    property CodigoSeleccionado: string read FCodigo;
    property NombreEje: string read FModelo.NombreEje;
    property Control: TcxTabControl read FPestanas;
  end;

  // Consultas informativas de caja, traspasos y ficha de artículos.
  TControlPestanasGridStock = class
  private
    FVista: TcxGridDBTableView;
    FPestanas: TControlPestanasEje;
    FArticulo: string;
    procedure Filtrar(const ACodigo: string);
    procedure QuitarFiltro(ALista: TcxFilterCriteriaItemList;
      AColumna: TcxGridDBColumn);
    function LeerModelo(ADatos: TDataSet;
      const ANombre: string): TModeloPestanasEje;
  public
    constructor Create(AVista: TcxGridDBTableView);
    destructor Destroy; override;
    procedure Actualizar(const ACodigoArticulo: string);
    procedure Ocultar;
    property Pestanas: TControlPestanasEje read FPestanas;
  end;

implementation

uses
  Winapi.Windows, System.Variants, cxGrid;

const
  ALTO_PESTANAS_96PPI = 28;

constructor TControlPestanasEje.Create(AOwner: TComponent;
  AParent: TWinControl; const AAlCambiar: TAlCambiarPestanaEje);
begin
  inherited Create;
  FAlCambiar := AAlCambiar;
  FPestanas := TcxTabControl.Create(AOwner);
  FPestanas.Parent := AParent;
  FPestanas.Align := alTop;
  FPestanas.HideTabs := False;
  FPestanas.Height := MulDiv(ALTO_PESTANAS_96PPI, AParent.CurrentPPI,
    USER_DEFAULT_SCREEN_DPI);
  FPestanas.Visible := False;
  FPestanas.OnChange := PestanasChange;
end;

destructor TControlPestanasEje.Destroy;
begin
  FreeAndNil(FPestanas);
  inherited;
end;

function TControlPestanasEje.HayPestanas: Boolean;
begin
  Result := HayPestanasEje(FModelo);
end;

procedure TControlPestanasEje.Ocultar;
begin
  FModelo := Default(TModeloPestanasEje);
  FCodigo := '';
  FPestanas.Visible := False;
end;

procedure TControlPestanasEje.SeleccionarTodas;
begin
  FCodigo := '';
  if HayPestanas then
  begin
    FCargando := True;
    try
      FPestanas.TabIndex := INDICE_PESTANA_TODAS;
    finally
      FCargando := False;
    end;
  end;
end;

procedure TControlPestanasEje.Mostrar(const AModelo: TModeloPestanasEje);
var
  sTexto: string;
begin
  FModelo := AModelo;
  if not HayPestanasEje(FModelo) then
    Ocultar
  else
  begin
    FCargando := True;
    try
      FPestanas.Tabs.BeginUpdate;
      try
        FPestanas.Tabs.Clear;
        for sTexto in TextosPestanasEje(FModelo) do
          FPestanas.Tabs.Add(sTexto);
      finally
        FPestanas.Tabs.EndUpdate;
      end;
      FPestanas.TabIndex := IndicePestanaEje(FModelo, FCodigo);
      FCodigo := CodigoPestanaEje(FModelo, FPestanas.TabIndex);
      FPestanas.Visible := True;
    finally
      FCargando := False;
    end;
  end;
end;

procedure TControlPestanasEje.PestanasChange(Sender: TObject);
begin
  if not FCargando then
  begin
    FCodigo := CodigoPestanaEje(FModelo, FPestanas.TabIndex);
    if Assigned(FAlCambiar) then
      FAlCambiar(FCodigo);
  end;
end;

constructor TControlPestanasGridStock.Create(AVista: TcxGridDBTableView);
var
  oGrid: TcxGrid;
begin
  inherited Create;
  FVista := AVista;
  oGrid := TcxGrid(FVista.Control);
  FPestanas := TControlPestanasEje.Create(oGrid, oGrid.Parent,
    procedure(const ACodigo: string)
    begin
      Filtrar(ACodigo);
    end);
  FPestanas.Control.Top := oGrid.Top;
end;

destructor TControlPestanasGridStock.Destroy;
begin
  FreeAndNil(FPestanas);
  inherited;
end;

procedure TControlPestanasGridStock.QuitarFiltro(
  ALista: TcxFilterCriteriaItemList; AColumna: TcxGridDBColumn);
var
  i: Integer;
  oItem: TcxCustomFilterCriteriaItem;
begin
  for i := ALista.Count - 1 downto 0 do
  begin
    oItem := ALista.Items[i];
    if oItem.IsItemList then
      QuitarFiltro(TcxFilterCriteriaItemList(oItem), AColumna)
    else if TcxFilterCriteriaItem(oItem).ItemLink = AColumna then
      FreeAndNil(oItem);
  end;
end;

procedure TControlPestanasGridStock.Filtrar(const ACodigo: string);
var
  oColumna: TcxGridDBColumn;
begin
  oColumna := FVista.GetColumnByFieldName('COPA');
  if Assigned(oColumna) then
  begin
    FVista.DataController.Filter.BeginUpdate;
    try
      QuitarFiltro(FVista.DataController.Filter.Root, oColumna);
      if ACodigo <> '' then
        FVista.DataController.Filter.Root.AddItem(
          oColumna, foEqual, ACodigo, ACodigo);
    finally
      FVista.DataController.Filter.EndUpdate;
    end;
    FVista.DataController.Filter.Active :=
      FVista.DataController.Filter.Root.Count > 0;
  end;
end;

function TControlPestanasGridStock.LeerModelo(ADatos: TDataSet;
  const ANombre: string): TModeloPestanasEje;
var
  aValores: TArray<string>;
  aUnidades: TArray<Double>;
  oMarca: TBookmark;
begin
  aValores := nil;
  aUnidades := nil;
  oMarca := ADatos.GetBookmark;
  ADatos.DisableControls;
  try
    ADatos.First;
    while not ADatos.Eof do
    begin
      aValores := aValores + [ADatos.FieldByName('COPA').AsString];
      aUnidades := aUnidades + [ADatos.FieldByName('Total').AsFloat];
      ADatos.Next;
    end;
  finally
    if ADatos.BookmarkValid(oMarca) then
      ADatos.GotoBookmark(oMarca);
    ADatos.FreeBookmark(oMarca);
    ADatos.EnableControls;
  end;
  Result := ModeloPestanasDeLineas(ANombre, nil, aValores, aUnidades);
end;

procedure TControlPestanasGridStock.Actualizar(
  const ACodigoArticulo: string);
var
  oDatos: TDataSet;
  oCopa: TField;
  oColumna: TcxGridDBColumn;
begin
  oDatos := FVista.DataController.DataSet;
  oCopa := nil;
  if Assigned(oDatos) and oDatos.Active then
    oCopa := oDatos.FindField('COPA');
  if Assigned(oCopa) and not (oDatos.State in dsEditModes) then
  begin
    if FArticulo <> ACodigoArticulo then
      FPestanas.SeleccionarTodas;
    FArticulo := ACodigoArticulo;
    oColumna := FVista.GetColumnByFieldName('COPA');
    if Assigned(oColumna) then
    begin
      oColumna.Caption := oCopa.DisplayLabel;
      oColumna.Width := 75;
      oColumna.HeaderAlignmentHorz := taLeftJustify;
    end;
    FPestanas.Mostrar(LeerModelo(oDatos, oCopa.DisplayLabel));
    Filtrar(FPestanas.CodigoSeleccionado);
  end
  else
    Ocultar;
end;


procedure TControlPestanasGridStock.Ocultar;
begin
  FArticulo := '';
  FPestanas.Ocultar;
end;

end.
