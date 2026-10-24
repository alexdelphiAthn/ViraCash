{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGestorGuiasGridMto                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Gestiona las guías y el selector de columnas de los mantenimientos.       }
{******************************************************************************}
unit inLibGestorGuiasGridMto;

interface

uses
  System.Classes, Vcl.Forms, Vcl.Menus, Uni, cxGrid,
  cxGridDBTableView, inLibInformesGuiasCache,
  inLibGridColumnChooser, inLibGuiasGridPersistenciaIntf,
  inLibLogIntf;

type
  TObtenerConsultaGuiasMto = function: TUniQuery of object;
  TEjecutarModalGuiasMto = procedure of object;

  TGestorGuiasGridMto = class
  private
    FFormulario: TForm;
    FGrid: TcxGrid;
    FVista: TcxGridDBTableView;
    FCache: IInformesGuiasCache;
    FPersistencia: IPersistenciaGuiasGrid;
    FObtenerConsulta: TObtenerConsultaGuiasMto;
    FEjecutarModal: TEjecutarModalGuiasMto;
    FMenu: TPopupMenu;
    FSqlOriginal: string;
    FCamposGuia: TStringList;
    FCamposGuiaTabla: TStringList;
    FColumnasVisibles: TStringList;
    FRegistroLog: IRegistroLog;
    function BuscarColumna(
      const ACampo: string): TcxGridDBColumn;
    function AbrirConsultaEnriquecida(
      AConsulta: TUniQuery;
      const ASqlOriginal: string): Boolean;
    procedure LiberarResultado(
      var AResultado: TGridGuiaResult);
    procedure ActualizarColumnas(
      ACampos, AVisibles: TStrings;
      AActualizarExistentes: Boolean);
    procedure CopiarLista(
      ADestino: TStringList;
      AOrigen: TStrings);
    procedure GuardarColumnasVisibles(
      AColumnas: TStringList);
    procedure MenuPopup(Sender: TObject);
    procedure ColumnaClick(Sender: TObject);
    procedure RenombrarClick(Sender: TObject);
    procedure NuevaGuiaClick(Sender: TObject);
  public
    constructor Create(
      AFormulario: TForm;
      AGrid: TcxGrid;
      AVista: TcxGridDBTableView;
      const ACache: IInformesGuiasCache;
      AObtenerConsulta: TObtenerConsultaGuiasMto;
      AEjecutarModal: TEjecutarModalGuiasMto;
      const ARegistroLog: IRegistroLog = nil);
    destructor Destroy; override;
    procedure AsignarPersistencia(
      const APersistencia: IPersistenciaGuiasGrid);
    procedure Aplicar(AConsulta: TUniQuery);
    procedure BorrarGuias;
    procedure ReaplicarVisibilidad;
    procedure ConstruirMenu;
    procedure AlternarColumna(AIndice: Integer);
    procedure RenombrarColumnas;
    procedure NuevaGuia;
    procedure LimpiarColumnasGuia;
    procedure ActualizarListas(
      ACampos, ACamposTabla, AVisibles: TStrings);
    property Menu: TPopupMenu read FMenu;
    property CamposGuia: TStringList read FCamposGuia;
    property CamposGuiaTabla: TStringList read FCamposGuiaTabla;
    property ColumnasVisibles: TStringList read FColumnasVisibles;
    property SqlOriginal: string read FSqlOriginal;
  end;

implementation

uses
  System.SysUtils, System.Generics.Collections, Vcl.Controls,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Graphics,
  inLibMsgComun, inLibRegistroLogNulo;

constructor TGestorGuiasGridMto.Create(
  AFormulario: TForm;
  AGrid: TcxGrid;
  AVista: TcxGridDBTableView;
  const ACache: IInformesGuiasCache;
  AObtenerConsulta: TObtenerConsultaGuiasMto;
  AEjecutarModal: TEjecutarModalGuiasMto;
  const ARegistroLog: IRegistroLog);
begin
  inherited Create;
  FFormulario := AFormulario;
  FGrid := AGrid;
  FVista := AVista;
  FCache := ACache;
  FPersistencia := nil;
  FObtenerConsulta := AObtenerConsulta;
  FEjecutarModal := AEjecutarModal;
  FRegistroLog := ARegistroLog;
  if not Assigned(FRegistroLog) then
    FRegistroLog := CrearRegistroLogNulo;
  FSqlOriginal := '';
  FCamposGuia := TStringList.Create;
  FCamposGuiaTabla := TStringList.Create;
  FColumnasVisibles := TStringList.Create;
  FColumnasVisibles.CaseSensitive := False;
  FMenu := TPopupMenu.Create(FFormulario);
  FMenu.OnPopup := MenuPopup;
  if Assigned(FGrid) then
    FGrid.PopupMenu := FMenu;
end;

destructor TGestorGuiasGridMto.Destroy;
begin
  if Assigned(FGrid) and (FGrid.PopupMenu = FMenu) then
    FGrid.PopupMenu := nil;
  FreeAndNil(FMenu);
  FreeAndNil(FColumnasVisibles);
  FreeAndNil(FCamposGuiaTabla);
  FreeAndNil(FCamposGuia);
  FPersistencia := nil;
  FCache := nil;
  inherited;
end;

procedure TGestorGuiasGridMto.AsignarPersistencia(
  const APersistencia: IPersistenciaGuiasGrid);
begin
  FPersistencia := APersistencia;
end;

function TGestorGuiasGridMto.BuscarColumna(
  const ACampo: string): TcxGridDBColumn;
var
  i: Integer;
  oColumna: TcxGridDBColumn;
begin
  Result := nil;
  i := 0;
  while (Result = nil) and (i < FVista.ColumnCount) do
  begin
    oColumna := FVista.Columns[i] as TcxGridDBColumn;
    if SameText(
      oColumna.DataBinding.FieldName, ACampo) then
      Result := oColumna;
    Inc(i);
  end;
end;

procedure TGestorGuiasGridMto.LiberarResultado(
  var AResultado: TGridGuiaResult);
begin
  FreeAndNil(AResultado.CamposNuevos);
  FreeAndNil(AResultado.CamposTabla);
  FreeAndNil(AResultado.ColumnasVisibles);
end;

function TGestorGuiasGridMto.AbrirConsultaEnriquecida(
  AConsulta: TUniQuery;
  const ASqlOriginal: string): Boolean;
begin
  Result := False;
  try
    AConsulta.Open;
    Result := True;
  except
    on E: Exception do
    begin
      FRegistroLog.RegistrarError(
        'AplicarGuiasGrid: error al reabrir query enriquecida: ' +
        E.Message);
      try
        AConsulta.Close;
        AConsulta.SQL.Text := ASqlOriginal;
        AConsulta.Open;
      except
        on E2: Exception do
          FRegistroLog.RegistrarError(
            'AplicarGuiasGrid: tampoco abre el SQL original tras ' +
            'restaurar: ' + E2.Message);
      end;
    end;
  end;
end;

procedure TGestorGuiasGridMto.CopiarLista(
  ADestino: TStringList;
  AOrigen: TStrings);
begin
  ADestino.Clear;
  if Assigned(AOrigen) then
    ADestino.Assign(AOrigen);
end;

procedure TGestorGuiasGridMto.ActualizarListas(
  ACampos, ACamposTabla, AVisibles: TStrings);
begin
  CopiarLista(FCamposGuia, ACampos);
  CopiarLista(FCamposGuiaTabla, ACamposTabla);
  CopiarLista(FColumnasVisibles, AVisibles);
end;

procedure TGestorGuiasGridMto.ActualizarColumnas(
  ACampos, AVisibles: TStrings;
  AActualizarExistentes: Boolean);
var
  i: Integer;
  sCampo: string;
  bVisible: Boolean;
  oColumna: TcxGridDBColumn;
begin
  FVista.BeginUpdate;
  try
    for i := 0 to ACampos.Count - 1 do
    begin
      sCampo := ACampos[i];
      bVisible := AVisibles.IndexOf(sCampo) >= 0;
      oColumna := BuscarColumna(sCampo);
      if not Assigned(oColumna) then
      begin
        oColumna := FVista.CreateColumn as TcxGridDBColumn;
        oColumna.DataBinding.FieldName := sCampo;
        oColumna.Caption := sCampo;
        oColumna.Visible := bVisible;
      end
      else if AActualizarExistentes then
        oColumna.Visible := bVisible;
    end;
  finally
    FVista.EndUpdate;
  end;
end;

procedure TGestorGuiasGridMto.Aplicar(
  AConsulta: TUniQuery);
var
  oResultado: TGridGuiaResult;
begin
  if Assigned(AConsulta) then
  begin
    oResultado := EnriquecerQueryConGuias(
      FPersistencia, FCache, FFormulario.Name,
      AConsulta, FRegistroLog);
    try
      if oResultado.Exito and
         (oResultado.CamposNuevos.Count > 0) then
      begin
        FSqlOriginal := oResultado.SqlOriginal;
        if AbrirConsultaEnriquecida(
          AConsulta, oResultado.SqlOriginal) then
        begin
          ActualizarColumnas(
            oResultado.CamposNuevos,
            oResultado.ColumnasVisibles,
            False);
          ActualizarListas(
            oResultado.CamposNuevos,
            oResultado.CamposTabla,
            oResultado.ColumnasVisibles);
        end;
      end;
    finally
      LiberarResultado(oResultado);
    end;
  end;
end;

procedure TGestorGuiasGridMto.BorrarGuias;
begin
  if not Assigned(FPersistencia) then
    raise Exception.Create(
      SErrorPersistenciaGuiasNoConfigurada);
  FPersistencia.Borrar('GRID:' + FFormulario.Name);
  if Assigned(FCache) then
    FCache.Invalidar;
end;

procedure TGestorGuiasGridMto.ReaplicarVisibilidad;
var
  i: Integer;
  sCampo: string;
  oColumna: TcxGridDBColumn;
begin
  if FCamposGuia.Count > 0 then
  begin
    for i := 0 to FVista.ColumnCount - 1 do
    begin
      oColumna := FVista.Columns[i] as TcxGridDBColumn;
      sCampo := oColumna.DataBinding.FieldName;
      if FCamposGuia.IndexOf(sCampo) >= 0 then
        oColumna.Visible :=
          FColumnasVisibles.IndexOf(sCampo) >= 0;
    end;
  end;
end;

procedure TGestorGuiasGridMto.ConstruirMenu;
var
  i: Integer;
  sCaption: string;
  sCampo: string;
  sTabla: string;
  oColumna: TcxGridDBColumn;
  oItem: TMenuItem;
  oSeparador: TMenuItem;
  oAccion: TMenuItem;
  oSubmenu: TMenuItem;
  oSubmenus: TDictionary<string, TMenuItem>;
begin
  FMenu.Items.Clear;
  oSubmenus := TDictionary<string, TMenuItem>.Create;
  try
    for i := 0 to FVista.ColumnCount - 1 do
    begin
      oColumna := FVista.Columns[i] as TcxGridDBColumn;
      sCampo := oColumna.DataBinding.FieldName;
      if sCampo <> '' then
      begin
        oItem := TMenuItem.Create(FMenu);
        sCaption := oColumna.Caption;
        if sCaption = '' then
          sCaption := sCampo;
        oItem.Caption := sCaption;
        oItem.Checked := oColumna.Visible;
        oItem.AutoCheck := False;
        oItem.Tag := i;
        oItem.OnClick := ColumnaClick;
        sTabla := FCamposGuiaTabla.Values[sCampo];
        if sTabla <> '' then
        begin
          if not oSubmenus.TryGetValue(
            sTabla, oSubmenu) then
          begin
            oSubmenu := TMenuItem.Create(FMenu);
            oSubmenu.Caption := Format(SCaptionGuiaTabla, [sTabla]);
            oSubmenus.Add(sTabla, oSubmenu);
          end;
          oSubmenu.Add(oItem);
        end
        else
          FMenu.Items.Add(oItem);
      end;
    end;
    oSeparador := TMenuItem.Create(FMenu);
    oSeparador.Caption := '-';
    FMenu.Items.Add(oSeparador);
    for oSubmenu in oSubmenus.Values do
      FMenu.Items.Add(oSubmenu);
  finally
    FreeAndNil(oSubmenus);
  end;
  oAccion := TMenuItem.Create(FMenu);
  oAccion.Caption := SCaptionRenombrarColumna;
  oAccion.OnClick := RenombrarClick;
  FMenu.Items.Add(oAccion);
  oAccion := TMenuItem.Create(FMenu);
  oAccion.Caption := SCaptionNuevaGuia;
  oAccion.OnClick := NuevaGuiaClick;
  FMenu.Items.Add(oAccion);
end;

procedure TGestorGuiasGridMto.AlternarColumna(
  AIndice: Integer);
var
  oColumna: TcxGridDBColumn;
begin
  if (AIndice >= 0) and
     (AIndice < FVista.ColumnCount) then
  begin
    oColumna := FVista.Columns[
      AIndice] as TcxGridDBColumn;
    oColumna.Visible := not oColumna.Visible;
  end;
end;

procedure TGestorGuiasGridMto.RenombrarColumnas;
var
  i: Integer;
  iTop: Integer;
  oFormulario: TForm;
  oPanelBotones: TPanel;
  oBotonAceptar: TButton;
  oBotonCancelar: TButton;
  oColumna: TcxGridDBColumn;
  oEtiqueta: TLabel;
  oEditor: TEdit;
  oEditores: TStringList;
begin
  oEditores := TStringList.Create;
  oFormulario := TForm.Create(FFormulario);
  try
    oFormulario.Caption := STituloRenombrarColumnas;
    oFormulario.Width := 620;
    oFormulario.Position := poScreenCenter;
    oFormulario.BorderStyle := bsDialog;
    iTop := 12;
    for i := 0 to FVista.ColumnCount - 1 do
    begin
      oColumna := FVista.Columns[i] as TcxGridDBColumn;
      if (oColumna.DataBinding.FieldName <> '') and
         oColumna.Visible then
      begin
        oEtiqueta := TLabel.Create(oFormulario);
        oEtiqueta.Parent := oFormulario;
        oEtiqueta.Left := 12;
        oEtiqueta.Top := iTop + 3;
        oEtiqueta.Width := 250;
        oEtiqueta.Caption :=
          oColumna.DataBinding.FieldName;
        oEtiqueta.Font.Color := clGray;
        oEditor := TEdit.Create(oFormulario);
        oEditor.Parent := oFormulario;
        oEditor.Left := 270;
        oEditor.Top := iTop;
        oEditor.Width := 320;
        oEditor.Text := oColumna.Caption;
        oEditor.Tag := i;
        oEditores.AddObject(
          oColumna.DataBinding.FieldName, oEditor);
        iTop := iTop + 30;
      end;
    end;
    oFormulario.ClientHeight := iTop + 55;
    oPanelBotones := TPanel.Create(oFormulario);
    oPanelBotones.Parent := oFormulario;
    oPanelBotones.Align := alBottom;
    oPanelBotones.Height := 45;
    oPanelBotones.BevelOuter := bvNone;
    oBotonAceptar := TButton.Create(oPanelBotones);
    oBotonAceptar.Parent := oPanelBotones;
    oBotonAceptar.Caption := SCaptionAplicar;
    oBotonAceptar.ModalResult := mrOk;
    oBotonAceptar.Left := 370;
    oBotonAceptar.Top := 8;
    oBotonAceptar.Width := 110;
    oBotonAceptar.Height := 30;
    oBotonCancelar := TButton.Create(oPanelBotones);
    oBotonCancelar.Parent := oPanelBotones;
    oBotonCancelar.Caption := SCaptionCancelar;
    oBotonCancelar.ModalResult := mrCancel;
    oBotonCancelar.Left := 490;
    oBotonCancelar.Top := 8;
    oBotonCancelar.Width := 110;
    oBotonCancelar.Height := 30;
    if oFormulario.ShowModal = mrOk then
    begin
      for i := 0 to oEditores.Count - 1 do
      begin
        oEditor := TEdit(oEditores.Objects[i]);
        oColumna := FVista.Columns[
          oEditor.Tag] as TcxGridDBColumn;
        if oEditor.Text <> oColumna.Caption then
          oColumna.Caption := oEditor.Text;
      end;
    end;
  finally
    FreeAndNil(oFormulario);
    FreeAndNil(oEditores);
  end;
end;

procedure TGestorGuiasGridMto.LimpiarColumnasGuia;
var
  i: Integer;
  sCampo: string;
  oColumna: TcxGridDBColumn;
begin
  if FCamposGuia.Count > 0 then
  begin
    FVista.BeginUpdate;
    try
      for i := FVista.ColumnCount - 1 downto 0 do
      begin
        oColumna := FVista.Columns[i] as TcxGridDBColumn;
        sCampo := oColumna.DataBinding.FieldName;
        if FCamposGuia.IndexOf(sCampo) >= 0 then
          oColumna.Free;
      end;
    finally
      FVista.EndUpdate;
    end;
    FCamposGuia.Clear;
  end;
end;

procedure TGestorGuiasGridMto.GuardarColumnasVisibles(
  AColumnas: TStringList);
var
  oColumnas: TStringList;
begin
  if not Assigned(FPersistencia) then
    raise Exception.Create(
      SErrorPersistenciaGuiasNoConfigurada);
  oColumnas := TStringList.Create;
  try
    oColumnas.Assign(AColumnas);
    oColumnas.StrictDelimiter := True;
    oColumnas.Delimiter := ';';
    FPersistencia.GuardarColumnasVisibles(
      'GRID:' + FFormulario.Name,
      oColumnas.DelimitedText);
  finally
    FreeAndNil(oColumnas);
  end;
end;

procedure TGestorGuiasGridMto.NuevaGuia;
var
  oConsulta: TUniQuery;
  oResultado: TGridGuiaResult;
  oCamposElegidos: TStringList;
begin
  if Assigned(FEjecutarModal) then
    FEjecutarModal;
  if Assigned(FCache) then
  begin
    FCache.Invalidar;
    FCache.Precargar;
  end;
  oConsulta := nil;
  if Assigned(FObtenerConsulta) then
    oConsulta := FObtenerConsulta;
  if Assigned(oConsulta) and oConsulta.Active then
  begin
    LimpiarColumnasGuia;
    if FSqlOriginal <> '' then
    begin
      oConsulta.Close;
      oConsulta.SQL.Text := FSqlOriginal;
    end;
    oResultado := EnriquecerQueryConGuias(
      FPersistencia, FCache, FFormulario.Name,
      oConsulta, FRegistroLog);
    try
      if oResultado.Exito and
         (oResultado.CamposNuevos.Count > 0) then
      begin
        FSqlOriginal := oResultado.SqlOriginal;
        oCamposElegidos := ElegirColumnasNuevas(
          FFormulario, oResultado.CamposNuevos);
        try
          oConsulta.Open;
          ActualizarColumnas(
            oResultado.CamposNuevos,
            oCamposElegidos,
            True);
          CopiarLista(
            FCamposGuia, oResultado.CamposNuevos);
          GuardarColumnasVisibles(oCamposElegidos);
        finally
          FreeAndNil(oCamposElegidos);
        end;
      end
      else if not oConsulta.Active then
        oConsulta.Open;
    finally
      LiberarResultado(oResultado);
    end;
  end;
end;

procedure TGestorGuiasGridMto.MenuPopup(
  Sender: TObject);
begin
  ConstruirMenu;
end;

procedure TGestorGuiasGridMto.ColumnaClick(
  Sender: TObject);
begin
  AlternarColumna(TMenuItem(Sender).Tag);
end;

procedure TGestorGuiasGridMto.RenombrarClick(
  Sender: TObject);
begin
  RenombrarColumnas;
end;

procedure TGestorGuiasGridMto.NuevaGuiaClick(
  Sender: TObject);
begin
  NuevaGuia;
end;

end.
