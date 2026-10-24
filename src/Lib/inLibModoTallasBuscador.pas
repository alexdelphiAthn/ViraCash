{******************************************************************************}
{                                                                              }
{  Módulo:       inLibModoTallasBuscador                                       }
{    Tipo:       Librería (presentación)                                       }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Desplegable de búsqueda incremental de artículos / SKU de la celda de     }
{    artículo, y selector visual de valores de atributo. Conoce DevExpress;    }
{    el SQL vive en el puerto IBusquedaSkusTallas.                             }
{******************************************************************************}
unit inLibModoTallasBuscador;

interface

uses
  System.SysUtils, System.Classes, System.Variants, Data.DB,
  Vcl.Forms, Vcl.Controls, Vcl.ExtCtrls,
  cxEdit, cxTextEdit, cxDropDownEdit, cxEditRepositoryItems,
  cxDBExtLookupComboBox, cxGrid, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView,
  inLibModoTallasIntf;

type
  TBuscadorSkusTallas = class
  private
    FBusqueda: IBusquedaSkusTallas;
    FVistaDocumento: TcxGridDBTableView;
    FOrigen: TDataSource;
    FRepoVistas: TcxGridViewRepository;
    FVista: TcxGridDBTableView;
    FColSku: TcxGridDBColumn;
    FColInput: TcxGridDBColumn;
    FRepoEditores: TcxEditRepository;
    FCombo: TcxEditRepositoryExtLookupComboBoxItem;
    FTimer: TTimer;
    FAlmacenStock: string;
    FRegistro: TRegistroTallas;
    FOnEntrarEdicion: TNotifyEvent;
    FOnEntradaElegida: TEntradaElegidaTallas;
    procedure CrearVista;
    procedure CrearCombo;
    procedure TimerBusqueda(Sender: TObject);
    procedure ComboInitPopup(Sender: TObject);
    procedure ComboCloseUp(Sender: TObject);
    procedure Registrar(const ATexto: string);
    function TextoTecleado(ACombo: TcxCustomEdit): string;
  public
    constructor Create(const ABusqueda: IBusquedaSkusTallas;
      AVistaDocumento: TcxGridDBTableView; ARegistro: TRegistroTallas);
    destructor Destroy; override;
    procedure Construir;
    // Cada tecleo rearma el debounce que abre el desplegable filtrado.
    procedure Rearmar;
    procedure ComboChange(Sender: TObject);
    procedure AbrirFiltrada(const ATexto: string);
    // Limpia el filtro interno del desplegable (IncSearching + Filter
    // del DataController): sin esto la lista se queda "pegada" a la
    // fila autocompletada aunque la consulta traiga mas filas.
    procedure LimpiarFiltro;
    procedure EstablecerAlmacenStock(const AValor: string);
    function Propiedades: TcxCustomEditProperties;
    property AlmacenStock: string read FAlmacenStock;
    property OnEntrarEdicion: TNotifyEvent read FOnEntrarEdicion
                                           write FOnEntrarEdicion;
    property OnEntradaElegida: TEntradaElegidaTallas
      read FOnEntradaElegida write FOnEntradaElegida;
  end;

implementation

uses
  inLibMsgArticulos;

constructor TBuscadorSkusTallas.Create(
  const ABusqueda: IBusquedaSkusTallas;
  AVistaDocumento: TcxGridDBTableView; ARegistro: TRegistroTallas);
begin
  inherited Create;
  FBusqueda := ABusqueda;
  FVistaDocumento := AVistaDocumento;
  FRegistro := ARegistro;
  FTimer := TTimer.Create(nil);
  FTimer.Enabled := False;
  FTimer.Interval := 350;
  FTimer.OnTimer := TimerBusqueda;
end;

destructor TBuscadorSkusTallas.Destroy;
begin
  // Desenganchar los eventos del REPOSITORIO antes de liberar nada:
  // liberar FRepoVistas dispara SetView(nil) en las properties del
  // combo, el editor cacheado del grid sincroniza su texto, salta su
  // Change y ComboChange tocaria FTimer ya liberado.
  if FCombo <> nil then
  begin
    FCombo.Properties.OnChange := nil;
    FCombo.Properties.OnInitPopup := nil;
    FCombo.Properties.OnCloseUp := nil;
  end;
  FreeAndNil(FTimer);
  FreeAndNil(FRepoEditores);
  FreeAndNil(FRepoVistas);
  FreeAndNil(FOrigen);
  FBusqueda := nil;
  inherited;
end;

procedure TBuscadorSkusTallas.Registrar(const ATexto: string);
begin
  if Assigned(FRegistro) then
    FRegistro(ATexto);
end;

procedure TBuscadorSkusTallas.CrearVista;
var
  Columna: TcxGridDBColumn;
begin
  FOrigen := TDataSource.Create(nil);
  FOrigen.DataSet := FBusqueda.Dataset;
  FRepoVistas := TcxGridViewRepository.Create(nil);
  FVista := FRepoVistas.CreateItem(TcxGridDBTableView)
              as TcxGridDBTableView;
  FVista.DataController.DataSource := FOrigen;
  FVista.DataController.KeyFieldNames := 'SKU';
  FVista.DataController.DataModeController.GridMode := True;
  // Sin sincronizar el cursor del dataset con la fila enfocada del
  // desplegable (como dbtvBusq de caja).
  FVista.DataController.DataModeController.SyncMode := False;
  FVista.OptionsView.GroupByBox := False;
  FVista.OptionsSelection.CellSelect := False;
  FVista.OptionsBehavior.IncSearch := False;
  FColSku := FVista.CreateColumn;
  FColSku.Caption := SCaptionColSku;
  FColSku.DataBinding.FieldName := 'SKU';
  FColSku.Width := 200;
  // Columna OCULTA duplicada del SKU que actua de ListFieldItem del
  // combo, con todo el buscado/filtrado desactivado: el lookup no tiene
  // donde morder y no autocompleta ni deja la lista "pegada".
  FColInput := FVista.CreateColumn;
  FColInput.DataBinding.FieldName := 'INPUT_BUSQUEDA';
  FColInput.PropertiesClass := TcxTextEditProperties;
  TcxTextEditProperties(FColInput.Properties).IncrementalSearch :=
    False;
  FColInput.Visible := False;
  FColInput.Options.Filtering := False;
  FColInput.Options.FilteringPopup := False;
  FColInput.Options.IncSearch := False;
  FColInput.Options.Grouping := False;
  Columna := FVista.CreateColumn;
  Columna.Caption := SCaptionColDescripcion;
  Columna.DataBinding.FieldName := 'DESCRIPCION';
  Columna.Width := 220;
  Columna := FVista.CreateColumn;
  Columna.Caption := SCaptionColCodigoBarras;
  Columna.DataBinding.FieldName := 'CODBARRAS';
  // 130: un EAN13 completo (el reparto de DropDownAutoWidth podia
  // dejarla corta y el codigo parecia truncado).
  Columna.Width := 130;
  Columna := FVista.CreateColumn;
  Columna.Caption := SCaptionColRefProveedor;
  Columna.DataBinding.FieldName := 'REFPRV';
  Columna.Width := 110;
  Columna := FVista.CreateColumn;
  Columna.Caption := SCaptionColStock;
  Columna.DataBinding.FieldName := 'STOCK';
  Columna.Width := 60;
end;

procedure TBuscadorSkusTallas.CrearCombo;
var
  Propiedades: TcxExtLookupComboBoxProperties;
begin
  FRepoEditores := TcxEditRepository.Create(nil);
  FCombo := FRepoEditores.CreateItem(
              TcxEditRepositoryExtLookupComboBoxItem)
              as TcxEditRepositoryExtLookupComboBoxItem;
  Propiedades := FCombo.Properties;
  Propiedades.View := FVista;
  Propiedades.KeyFieldNames := 'SKU';
  Propiedades.ListFieldItem := FColInput;
  Propiedades.DropDownListStyle := lsEditList;
  Propiedades.IncrementalFiltering := False;
  Propiedades.AutoSearchOnPopup := False;
  Propiedades.DropDownRows := 15;
  Propiedades.DropDownAutoWidth := True;
  Propiedades.ImmediateDropDownWhenKeyPressed := False;
  Propiedades.OnInitPopup := ComboInitPopup;
  Propiedades.OnCloseUp := ComboCloseUp;
  // En el repositorio: los clones de properties heredan el evento (el
  // hook por editor se pierde con AlwaysShowEditor).
  Propiedades.OnChange := ComboChange;
end;

procedure TBuscadorSkusTallas.Construir;
begin
  if FRepoVistas = nil then
  begin
    CrearVista;
    CrearCombo;
  end;
end;

function TBuscadorSkusTallas.Propiedades: TcxCustomEditProperties;
begin
  Result := nil;
  if FCombo <> nil then
    Result := FCombo.Properties;
end;

procedure TBuscadorSkusTallas.EstablecerAlmacenStock(
  const AValor: string);
begin
  if FAlmacenStock <> AValor then
  begin
    FAlmacenStock := AValor;
    FBusqueda.Invalidar;
  end;
end;

procedure TBuscadorSkusTallas.Rearmar;
begin
  // Guarda: el Change puede saltar en plena destruccion del modo.
  if FTimer <> nil then
  begin
    FTimer.Enabled := False;
    FTimer.Enabled := True;
  end;
end;

procedure TBuscadorSkusTallas.ComboChange(Sender: TObject);
begin
  Rearmar;
end;

function TBuscadorSkusTallas.TextoTecleado(
  ACombo: TcxCustomEdit): string;
var
  Combo: TcxExtLookupComboBox;
begin
  // Text, no EditingValue (el texto libre no llega alli); y si el combo
  // autocompleto, lo tecleado es lo previo a la seleccion.
  Result := '';
  if ACombo is TcxExtLookupComboBox then
  begin
    Combo := TcxExtLookupComboBox(ACombo);
    Result := Combo.Text;
    if Combo.SelLength > 0 then
      Result := Copy(Result, 1, Combo.SelStart);
    Result := Trim(Result);
  end;
end;

procedure TBuscadorSkusTallas.TimerBusqueda(Sender: TObject);
var
  Editor: TcxCustomEdit;
  Combo: TcxExtLookupComboBox;
  sTexto: string;
begin
  FTimer.Enabled := False;
  if not FVistaDocumento.Controller.EditingController.IsEditing then
    Registrar('ModoTallas.Busq: sin editor activo')
  else
  begin
    Editor := FVistaDocumento.Controller.EditingController.Edit;
    if not (Editor is TcxExtLookupComboBox) then
      Registrar('ModoTallas.Busq: editor no es combo (' +
                Editor.ClassName + ')')
    else
    begin
      Combo := TcxExtLookupComboBox(Editor);
      sTexto := TextoTecleado(Combo);
      Registrar('ModoTallas.Busq: texto="' + sTexto + '"');
      if Length(sTexto) >= 3 then
      begin
        AbrirFiltrada(sTexto);
        Registrar(Format('ModoTallas.Busq: %d coincidencias',
                         [FBusqueda.Dataset.RecordCount]));
        if not Combo.DroppedDown then
          Combo.DroppedDown := True;
      end;
    end;
  end;
end;

procedure TBuscadorSkusTallas.AbrirFiltrada(const ATexto: string);
begin
  if FVista <> nil then
  begin
    // Siempre: aunque la consulta ya este abierta con el mismo filtro,
    // el desplegable puede tener filtro interno pegado.
    LimpiarFiltro;
    Screen.Cursor := crHourGlass;
    FVista.BeginUpdate;
    try
      // Desenganchar la vista mientras se recambia la consulta evita
      // que reaplique su filtro sobre el dataset a medio abrir.
      FVista.DataController.DataSource := nil;
      FBusqueda.Aplicar(ATexto, FAlmacenStock);
      FVista.DataController.DataSource := FOrigen;
      FVista.DataController.Refresh;
    finally
      FVista.EndUpdate;
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TBuscadorSkusTallas.LimpiarFiltro;
begin
  if FVista <> nil then
  begin
    FVista.BeginUpdate;
    try
      FVista.Controller.IncSearchingText := '';
      FVista.DataController.Filter.Clear;
      FVista.DataController.Filter.Active := False;
      FVista.DataController.Filter.AutoDataSetFilter := False;
      // RESET imprescindible: sin Refresh la vista sigue mostrando el
      // conjunto filtrado viejo aunque el filtro ya este vacio.
      FVista.DataController.Refresh;
    finally
      FVista.EndUpdate;
    end;
  end;
end;

procedure TBuscadorSkusTallas.ComboInitPopup(Sender: TObject);
var
  sTexto: string;
begin
  sTexto := '';
  if Sender is TcxCustomEdit then
    sTexto := TextoTecleado(TcxCustomEdit(Sender));
  // Con el desplegable abierto, el Enter elige fila (no Tab).
  if Assigned(FOnEntrarEdicion) then
    FOnEntrarEdicion(Sender);
  AbrirFiltrada(sTexto);
end;

procedure TBuscadorSkusTallas.ComboCloseUp(Sender: TObject);
var
  sEntrada: string;
begin
  LimpiarFiltro;
  // NO se restaura aqui el EnterAsTab: el foco sigue en la celda y el
  // siguiente Enter debe llegar al grid (mismo arreglo que
  // inLibGridArticulos).
  if Sender is TcxCustomEdit then
  begin
    sEntrada := Trim(VarToStr(TcxCustomEdit(Sender).EditValue));
    if (sEntrada <> '') and Assigned(FOnEntradaElegida) then
      FOnEntradaElegida(sEntrada);
  end;
end;

end.
